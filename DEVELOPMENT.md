# DEVELOPMENT.md — Contributing & Architecture

Guide for developers maintaining or extending the `apm-gerador-template` APM Skill.

## Project Overview

`apm-gerador-template` is an APM (Agent Package Manager) skill that scaffolds new Java projects using the **Hexagonal Architecture** pattern. It:

1. **Conducts a structured interview** with the user to gather project requirements
2. **Fetches template data** from the remote reference repository (`heandroro/java-hexagonal-template`)
3. **Generates adapted files locally** by:
   - Reading template configuration (TEMPLATE-MANIFEST.json, GENERATOR.json)
   - Substituting project-specific tokens (namespace, project name, database, etc.)
   - Adapting module selection based on user choices
4. **Validates the generated project** using Maven

All generation happens locally in the user's workspace — no commits or pushes are automatic.

## Critical Files & Directories

| Path | Purpose | Maintainer Notes |
|------|---------|------------------|
| `.apm/skills/gerador-scaffold-java/SKILL.md` | Main skill instruction for LLM | Update when Pré-Phase 1 or any phase logic changes |
| `.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh` | Orchestrates parallel GitHub API calls for template fetching | Core I/O logic; careful with path changes |
| `.apm/skills/gerador-scaffold-java/scripts/lib/cache.sh` | Per-file cache with 24h TTL | Shared by fetch-template.sh; affects all runs |
| `.apm/skills/gerador-scaffold-java/references/files-to-adapt.md` | Token substitution rules by file type | Update when new token types added to template |
| `.apm/skills/gerador-scaffold-java/prompts/new-java-hexagonal-project.prompt.md` | Interview questions and flow | Update when adding new user questions |
| `.apm/skills/gerador-scaffold-java/references/module-dependencies.md` | Maven dependency rules (pom.xml format) | Update when template modules change |

## API Contract: Template Fetch Scripts

### Status Code Contract (fetch-template.sh and fetch-template-git.sh)

Both fetch scripts return the same JSON contract and exit codes, ensuring transparent fallback:

**Exit Codes**:
| Code | Meaning | Use Case | JSON Status |
|------|---------|----------|-------------|
| `0` | Complete success (all 3 files obtained) | All files available in cache/network | `status: 0` |
| `1` | Complete failure (no files obtained) | gh CLI unavailable OR git clone failed | `status: 1` (with error message) |

**JSON Contract (stdout)**:
```json
{
  "files": {
    "TEMPLATE-MANIFEST.json": "{ ...content... }",
    "GENERATOR.json": "{ ...content... }",
    "README.md": "..."
  },
  "metadata": {
    "source": "gh-cli",        // or "git-clone-first" or "git-pull"
    "duration": "3s"           // only in gh-cli
  },
  "status": 0
}
```

**For SKILL.md / LLM Integration**:
- Always check `status` field in JSON response
- If `status == 0`: proceed with generation using files from JSON
- If `status == 1`: script already failed with error message; present error to user
- Files are always in `.files{}` object (same structure regardless of source)

---

## Architecture: Template Data Fetch

### Overview

The skill needs to read template configuration files from the remote `java-hexagonal-template` repository. This happens in **Pré-Fase 1** via an intelligent orchestration:

```
Pré-Fase 1 (fetch orchestration)
├─ Try: gh-cli script (.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh)
│  ├─ Parallel batches (4 files at a time)
│  ├─ Per-file caching (24h TTL)
│  ├─ Auto-retry only failed files
│  └─ Return: JSON with status code (0/1/2)
│
└─ Fallback: git clone (.apm/skills/gerador-scaffold-java/scripts/fetch-template-git.sh)
   ├─ Optimized shallow clone (~30-50MB with --depth=1, --sparse, --filter=blob:none)
   ├─ Per-file cache with 24h TTL
   ├─ Incremental updates via git pull
   └─ Return: Same JSON contract (files + status code)
```

### Why Hybrid Strategy (gh CLI + git clone)?

**Token Economy**: 
- Both approaches: ~5K tokens (metadata only, files in `.cache/`)
- Why not MCP alone: ~150K tokens (all files in response to LLM) = 97% worse

**Resilience**:
- Per-file cache: if fetch fails, retry only that file
- Exponential backoff: avoids rate limits  
- Status codes (0/1/2) enable transparent fallback to git clone
- Two independent sources: works if either gh CLI or git is available

**Performance**:
- Cache hit (24h TTL): ~100ms (both sources)
- gh CLI cache miss: ~3-5s (parallel batches)
- git clone first run: ~2-5min (then pulls are ~1s)
- Universal availability: git exists everywhere

### Fetch Orchestration: Detailed Flow

#### Step 1: Try gh-CLI Script

Script: `.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh`

```bash
# Returns JSON with status code
result=$(.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh)
exit_code=$?
```

**Status Codes**:
- `0`: Complete success (all files obtained)
- `1`: Complete failure (gh CLI unavailable or auth failed)
- `2`: Partial success (some files obtained, others missing)

**JSON Output**:
```json
{
  "files": {
    "TEMPLATE-MANIFEST.json": "{ ...content... }",
    "GENERATOR.json": "{ ...content... }",
    "README.md": "..."
  },
  "missing": ["file-xyz"],          // Only if status = 2
  "metadata": {
    "source": "gh-cli",
    "batches": 2,
    "duration": "3s"
  },
  "status": 0
}
```

#### Step 2: Interpret Status Code

| Status | Meaning | Action |
|--------|---------|--------|
| `0` | Complete success (all files obtained) | Use all files from JSON directly |
| `1` | Complete failure (gh CLI unavailable) | Fallback: use git clone for all 3 files |
| `2` | Partial success (some cached) | Use cached files + git clone for missing |

#### Step 3: Cache Location

Cache is stored locally in the skill directory:
```
.apm/skills/gerador-scaffold-java/cache/
├── files/
│   ├── TEMPLATE-MANIFEST.json
│   ├── GENERATOR.json
│   ├── README.md
│   └── files.meta              # Timestamp (24h TTL)
```

### fetch-template.sh: Design

**Location**: `.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh`

**Key Functions**:
- `fetch_file_with_cache(file, retry_count)` — Fetch single file, return from cache if valid
- `fetch_batch()` — Parallel fetch of 4 files using `xargs`
- `get_failed_files()` — Detect which files failed (via `.err` markers)
- `retry_failed_files()` — Auto-retry with exponential backoff
- `build_json_output()` — Assemble JSON with status code

**Parallelism**: Files are fetched in batches using `xargs -P 4` (up to 4 parallel requests).

**Error Handling**:
- Success: Save to `.cache/files/{filename}.json`
- Failure: Save error marker to `.cache/files/{filename}.err`
- Auto-retry: Sleep `2^retry_count` seconds, then retry only failed files

### lib/cache.sh: Design

**Location**: `.apm/skills/gerador-scaffold-java/scripts/lib/cache.sh`

**Key Functions**:

| Function | Purpose |
|----------|---------|
| `files_cache_is_valid()` | Check if cache exists and is < 24h old |
| `files_cache_load()` | Return cache directory path (if valid) |
| `files_cache_mark_valid()` | Reset TTL timestamp after successful fetch |
| `files_cache_clean()` | Remove expired cache (≥ 24h old) |
| `cache_status()` | Print cache age and size |

**TTL Logic**: 24 hours from `files.meta` timestamp. After 24h, next fetch is from network.

**Path**: Cache lives in skill directory (`.../cache/files/`), not in `.apm/.cache/` (global).

### fetch-template-git.sh: Design (Fallback Strategy)

**Location**: `.apm/skills/gerador-scaffold-java/scripts/fetch-template-git.sh`

**Purpose**: Universal fallback when gh CLI is unavailable. Uses optimized shallow clone.

**Key Optimizations**:
- `--depth=1`: Clone only latest commit (no history)
- `--single-branch`: Only main branch (no other branches)
- `--filter=blob:none`: Lazy-load file contents (minimal download)
- `--sparse`: Sparse checkout mode (only needed files)

**Result**: ~30-50MB local clone (vs 500MB full clone)

**Cache Strategy**:
- Per-file cache in `.cache/files/` directory
- 24h TTL via `.cache/files/files.meta` timestamp
- Incremental updates via `git pull --ff-only` (only new changes)

**Same Interface**: Returns identical JSON contract to fetch-template.sh (files + status code)

## Template Configuration (Centralized)

Template repository details are centralized in:
```
.apm/skills/gerador-scaffold-java/lib/template-config.sh
```

**Default values**:
- `TEMPLATE_OWNER=heandroro`
- `TEMPLATE_REPO=java-hexagonal-template`
- `TEMPLATE_BRANCH=main`
- `TEMPLATE_FILES=(TEMPLATE-MANIFEST.json GENERATOR.json README.md)`
- `TEMPLATE_CACHE_DIR=.cache/files`
- `TEMPLATE_CACHE_TTL=$((24 * 60 * 60))` (24 hours)

**Overridable via environment variables** (before running fetch scripts):
```bash
export TEMPLATE_OWNER=myorg
export TEMPLATE_REPO=my-template
export TEMPLATE_BRANCH=develop
.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh
```

**Why centralized?**
- Single source of truth (resolves coupling #1)
- Easy to update for multi-template support (future)
- Consistent values across all scripts (fetch-template.sh, fetch-template-git.sh)
- Template is fully configurable without code changes

---

## Skill Development: Key Phases

### Pré-Fase 1: Fetch Orchestration

**Responsibility**: Obtain template data (TEMPLATE-MANIFEST.json, GENERATOR.json) via gh-cli or MCP.

**Entry Point**: Shell script or SKILL.md Pré-Phase 1 logic.

**Output**: JSON with files + status code.

**Maintenance**: If template structure changes (new files, new tokens), update fetch list in script.

### Fase 1: Structured Interview

**Responsibility**: Ask user 5+ questions (namespace, project name, modules, etc.).

**Entry Point**: SKILL.md Fase 1 section.

**Data Source**: GENERATOR.json (profiles[], questions[]) — read in Pré-Phase 1.

**Output**: Collected variables (NAMESPACE, PROJECT_NAME, selectedModules[]).

**Maintenance**: If adding new questions, update prompts/new-java-hexagonal-project.prompt.md.

### Fase 2: Summary & Confirmation

**Responsibility**: Show user a summary of all selections, ask "Confirm generation?".

**Entry Point**: SKILL.md Fase 2 section.

**Output**: User confirms (yes/no).

**Maintenance**: If Phase 1 collects new variables, update summary template.

### Fase 4: Generation

**Responsibility**: Generate all files locally with token substitution.

**Entry Point**: SKILL.md Fase 4 section (4.1 to 4.5 substeps).

**Key Sub-steps**:
- 4.1: Reutilize template files already in context from Pré-Fase 1 (no MCP calls)
- 4.2: Build token substitution map
- 4.3: Generate files (parallel Write calls)
- 4.4: Validate Maven
- 4.5: Report execution metrics

**Important**: Phase 4 does NOT require MCP — all template data (TEMPLATE-MANIFEST.json, GENERATOR.json) was already fetched in Pré-Fase 1 via gh CLI or git clone. Simply reuse those cached/in-context values.

**Maintenance**: Update token map if new tokens added to template. Update file paths if template structure changes.

## Critical Clarification: Phase 4 Does NOT Require MCP

### Why Phase 4 is independent from MCP

**Phase 4 generation does NOT make any MCP calls** — it only consumes template data that was already fetched in Pré-Fase 1.

**Data Flow**:
```
Pré-Fase 1: fetch-template.sh (gh CLI) or fetch-template-git.sh (git clone)
    ↓
    Returns JSON with 3 files (in context):
    • TEMPLATE-MANIFEST.json
    • GENERATOR.json  
    • README.md
    ↓
Phase 4: LLM reutilizes these 3 files from context
    • No additional network calls needed
    • No MCP required at execution time
    • Skill is fully self-contained after Pré-Fase 1
```

**Implication for users**:
- If gh CLI is available: entire skill runs with ~5K tokens (just metadata, no MCP)
- If gh CLI unavailable: falls back to git clone (still no MCP needed)
- MCP is optional fallback in apm.yml, not required

### Why this matters for maintenance

If you add new token types or modules to the template:
1. Update `TEMPLATE-MANIFEST.json.replaceTokens[]` in the template repo (heandroro/java-hexagonal-template)
2. Update `SKILL.md` table at "4.2 — Token substitution map" with new tokens
3. Update `./references/files-to-adapt.md` with new file types or rules
4. **Do NOT add new MCP calls to Phase 4** — the template data is already in context

---

## Token Substitution

**Token Mapping** (from TEMPLATE-MANIFEST.json.replaceTokens[]):

| Token | Value | Condition |
|-------|-------|-----------|
| `com.mycompany.template` | `{NAMESPACE}` | Always |
| `com.mycompany` | `{NAMESPACE_ROOT}` | Always |
| `java-hexagonal-template` | `{PROJECT_NAME}` | Always |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | Always |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Always |
| `user-events-queue` | `{PROJECT_NAME_SNAKE}-events-queue` | If infra-sqs selected |
| `user-events-topic` | `{PROJECT_NAME_SNAKE}-events-topic` | If infra-sns selected |
| `users` | `{ENTITY_NAME_PLURAL}` | If infra-dynamodb selected |

**Rules by File Type** (from references/files-to-adapt.md):

| Pattern | Substitution Rule |
|---------|------------------|
| `*.java` | Replace package declarations, imports, class tokens |
| `pom.xml` | Replace groupId, artifactId, properties |
| `*.yml` / `*.yaml` | Replace property keys and values |
| `Dockerfile*` | Replace environment variables |
| `docker-compose.yml` | Replace service names, environment variables |

**Maintenance**: If template adds new file types or tokens, update rules in references/files-to-adapt.md.

## References

### External Dependencies

- **gh CLI** (`github.com/cli/cli`) — Recommended for template fetching (primary source, ~3-5s, 5K tokens)
- **git** — Universal fallback for template fetching (always available, ~30-50MB cache)
- **Template Repository** (`heandroro/java-hexagonal-template@main`) — Source of truth for modules, tokens, capabilities
- **GitHub MCP** (optional) — For advanced GitHub integration beyond template fetching

### Internal Documentation

- `SKILL.md` — LLM instructions for running the skill (all 5 phases)
- `prompts/new-java-hexagonal-project.prompt.md` — Interview questions and flow
- `references/files-to-adapt.md` — Token substitution rules
- `references/module-dependencies.md` — Maven pom.xml formatting rules
- `references/readme-template.md` — Template for generated README.md

## Testing & Verification

### Manual Testing

1. **Verify fetch-template.sh**:
   ```bash
   .apm/skills/gerador-scaffold-java/scripts/fetch-template.sh
   echo "Status: $?"  # Should be 0 (or 1 if gh CLI not installed)
   ```

2. **Verify cache creation**:
   ```bash
   ls -la .apm/skills/gerador-scaffold-java/cache/files/
   # Should see: TEMPLATE-MANIFEST.json, GENERATOR.json, README.md
   ```

3. **Verify cache TTL**:
   ```bash
   # Run script again within 24h
   .apm/skills/gerador-scaffold-java/scripts/fetch-template.sh
   # Should be instant (~100ms) on cache hit
   ```

4. **Run full skill interview** (in Claude Code):
   - Say "criar novo projeto Java"
   - Go through all phases (Fase 1 interview → Fase 2 confirmation → Fase 4 generation)
   - Verify generated files in workspace
   - Verify no phantom tokens in generated code

### What to Check After Skill Changes

- [ ] No `com.mycompany.template` tokens in generated files
- [ ] Correct namespace from user input (e.g., `com.example.myapp`)
- [ ] Correct project name in pom.xml and application.yml
- [ ] Maven compiles & tests pass: `mvn clean package`
- [ ] Correct modules included (e.g., if user chose "database = postgres", infra-postgres/ should exist)
- [ ] Docker compose includes only selected services

### Performance Metrics to Monitor

- **Fetch time** (cold): ~3-5 seconds (parallel batches)
- **Fetch time** (warm/cached): ~100ms (disk read)
- **Token cost** (per run): ~5K tokens (metadata only)
- **Cache size**: ~80KB (compressed gzip, if per-file compression added)
- **MCP fallback rate**: Should be <5% (only if gh CLI unavailable)

## Future Enhancements

- [ ] **Cache compression**: Gzip per-file cache to 82% smaller
- [ ] **Metrics collection**: Track fetch time, cache hit %, fallback rate
- [ ] **GitHub App auth**: Increase rate limit from 5,000 to 15,000 req/hour
- [ ] **Template versioning**: Support multiple template versions (branches/tags)
- [ ] **Conflict resolution**: Handle module incompatibilities (e.g., postgres vs mariadb)
- [ ] **Dry-run mode**: Generate files without writing to disk (for preview)

## Questions?

See `SKILL.md` for the actual interview flow, or `README.md` for user-facing documentation.
