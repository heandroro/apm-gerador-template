# APM Scripts — Template Fetch Orchestration

This directory contains helper scripts for the `gerador-scaffold-java` skill, with a focus on efficient template data fetching and caching.

## fetch-template.sh

**Purpose**: Fetch template configuration files from GitHub with intelligent parallel batching, per-file caching, and automatic retry.

**Design Goals**:
- ✅ Reduce token cost: LLM receives ~5K metadata instead of ~150K file contents
- ✅ Resilience: Per-file cache + auto-retry for failed files (not all-or-nothing)
- ✅ Performance: Cache hit (24h TTL) = ~100ms; miss = ~3-5s network fetch
- ✅ UX: Invisible to user; no multiple confirmations; single status code tells SKILL.md what to do
- ✅ Fallback: Automatic fallback to GitHub MCP if gh CLI unavailable

### Quick Start

```bash
# Use defaults (fetch from heandroro/java-hexagonal-template@main)
.apm/scripts/fetch-template.sh

# Force cache refresh (ignore 24h TTL)
.apm/scripts/fetch-template.sh heandroro java-hexagonal-template main 4 true

# Custom owner/repo
.apm/scripts/fetch-template.sh myorg my-template-repo main 4 false
```

### How It Works

#### Phase 1: Parallel Fetch with Per-File Caching

```
Batch 1 (4 files in parallel):
├─ TEMPLATE-MANIFEST.json
│  ├─ Check cache → cache hit → return
│  └─ Fetch via gh api → save to .cache/files/TEMPLATE-MANIFEST.json
├─ GENERATOR.json → same flow
├─ README.md → same flow
└─ (4th file if exists)

Batch 2 (next 4 files in parallel)
└─ ...
```

**Output**:
- ✅ Files: Cached in `.cache/files/*.json` (individual files)
- ✅ Status markers: Error files `.cache/files/*.err` if any fetch failed

#### Phase 2: Error Detection & Auto-Retry

```
After all batches complete:
1. Scan for .cache/files/*.err
2. If found:
   - Sleep 2s (exponential backoff: 2^retry_count)
   - Retry ONLY failed files (not successful ones)
   - Repeat up to max_retries times
3. After max_retries exhausted:
   - Successful files → in JSON output
   - Failed files → listed in "missing" array
```

#### Phase 3: JSON Output with Status

Script returns JSON (stdout) with status code (exit status):

| Status | Meaning | When | Action |
|--------|---------|------|--------|
| **0** | Complete success | All files obtained | SKILL.md uses all files directly |
| **1** | Complete failure | gh CLI unavailable OR auth failed | SKILL.md fallback to GitHub MCP |
| **2** | Partial success | Some files obtained, others failed | SKILL.md uses cached + MCP for missing |

Example output (status 0):
```json
{
  "files": {
    "TEMPLATE-MANIFEST.json": "{ \"templateName\": \"...\", ... }",
    "GENERATOR.json": "{ \"profiles\": [...], ... }",
    "README.md": "# Template..."
  },
  "metadata": {
    "source": "gh-cli",
    "batches": 1,
    "duration": "2s"
  },
  "status": 0
}
```

Example output (status 2 - partial):
```json
{
  "files": {
    "TEMPLATE-MANIFEST.json": "{ ... }",
    "GENERATOR.json": "{ ... }"
  },
  "missing": ["README.md"],
  "metadata": { ... },
  "status": 2
}
```

### Cache Structure

```
.cache/
├── files/                           # Per-file cache directory (primary)
│   ├── TEMPLATE-MANIFEST.json       # Successful fetch
│   ├── GENERATOR.json               # Successful fetch
│   ├── README.md.err                # Error marker (fetch failed)
│   └── files.meta                   # Timestamp (24h TTL)
└── (legacy: *.json.gz, cache.meta — deprecated after gh-cli migration)
```

**TTL**: 24 hours from `files.meta` timestamp. After 24h, cache is ignored (forces refresh via network).

### lib/cache.sh

Utility functions for cache operations:

| Function | Purpose |
|----------|---------|
| `cache_is_valid()` | Check if monolithic cache exists & <24h old |
| `files_cache_is_valid()` | Check if per-file cache exists & <24h old |
| `cache_load()` | Load monolithic cache (gunzip) |
| `files_cache_load()` | Return per-file cache dir if valid |
| `cache_save()` | Save monolithic cache (gzip) |
| `files_cache_mark_valid()` | Mark per-file cache as fresh (reset TTL) |
| `files_cache_clean()` | Remove expired per-file cache |

### Integration with SKILL.md

SKILL.md Pré-Fase 1 flow:

1. **Try gh-cli approach** (primary):
   ```bash
   status=$(.apm/scripts/fetch-template.sh)
   exit_code=$?
   ```

2. **Interpret status code**:
   ```bash
   case $exit_code in
     0) # Complete success → use all files ;;
     1) # Fallback to MCP → make get_file_contents calls ;;
     2) # Partial success → use cached + MCP for missing ;;
   esac
   ```

3. **Fallback to MCP**: If exit_code != 0, call GitHub MCP for missing files.

### Performance Comparison

| Scenario | gh-cli | MCP Direct |
|----------|--------|-----------|
| **Cold (no cache)** | ~3-5s network + parsing | ~5s (same) |
| **Warm (cache hit)** | ~100ms disk read | N/A (MCP has no cache layer) |
| **Token cost** | ~5K (metadata only) | ~150K (file contents) |
| **Fallback on error** | Automatic (→ MCP) | N/A |

### Troubleshooting

**Problem**: Script returns status 1 (complete failure)

**Possible causes**:
- gh CLI not installed: `which gh` → install from https://github.com/cli/cli
- gh not authenticated: `gh auth status` → run `gh auth login`
- Network unreachable: Check internet connection & GitHub availability

**Solution**: Script will output error message to stderr. Check message and follow instructions (install gh, authenticate, or wait for network).

**Problem**: Script returns status 2 (partial success) repeatedly

**Possible causes**:
- Network instability (some requests timeout)
- GitHub API rate limit (unlikely for 3-file fetch, but possible)
- Firewall/proxy blocking some requests

**Solution**: Check `.cache/files/*.err` to see which files failed. Manual fallback to MCP will cover missing files. Next run will retry auto-retry logic.

### Testing the Script

```bash
# Test with defaults
.apm/scripts/fetch-template.sh

# Test with custom owner/repo (your fork)
.apm/scripts/fetch-template.sh myuser my-fork-of-template

# Force refresh (ignore cache)
.apm/scripts/fetch-template.sh heandroro java-hexagonal-template main 4 true

# Check exit code
.apm/scripts/fetch-template.sh
echo "Exit code: $?"  # Should be 0, 1, or 2

# Parse JSON output
result=$(.apm/scripts/fetch-template.sh)
status=$(echo "$result" | jq -r '.status')
missing=$(echo "$result" | jq -r '.missing[]' 2>/dev/null || echo "none")
```

### Future Enhancements

- **Compression**: Save per-file cache as gzip (82% space savings) — optional, trades disk I/O for space
- **Retry backoff tuning**: Exponential backoff formula `2^retry_count` may need adjustment based on observed failure patterns
- **Metrics collection**: Track success rate, avg fetch time, cache hit %, for monitoring in production
- **Concurrent requests limit**: Currently uses `xargs -P 8`, could be tuned based on GitHub API rate limits

## Dependencies

- **gh CLI**: https://github.com/cli/cli — must be installed & authenticated
- **jq**: JSON processor — used for parsing JSON in shell
- **bash 4+**: Modern bash features (associative arrays, etc.)
- **Standard GNU tools**: `gzip`, `date`, `mktemp`, `sed`

All are available on macOS (via Homebrew) and modern Linux distributions.
