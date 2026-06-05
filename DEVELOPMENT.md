# apm-gerador-template — Development Guide

This guide is for maintaining and evolving the skill. It is **LLM-agnostic** — applies to any agent framework (Claude Code, GitHub Copilot Workspace, etc.) that uses the APM specification.

---

## Project Overview

**apm-gerador-template** is an APM skill for scaffolding new Java Hexagonal Architecture projects.

**What it does:**
- Conducts a structured interview to gather project requirements
- Reads template data from [heandroro/java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template) via GitHub MCP
- Generates a complete, ready-to-build Maven multi-module project locally with:
  - Token substitution (namespace, project name, database name, etc.)
  - Selective module inclusion (based on capabilities: API vs Worker, persistence type, cache, messaging, HTTP client)
  - Adapted configuration files

**Design principle:** Read template once → adapt by rules → generate locally. No repository operations (commits, pushes, PRs).

---

## Architecture

### Directory Structure

```
apm.yml                                   # Skill metadata & dependencies
README.md                                 # User-facing setup guide
AGENTS.md                                 # Global APM guidance
DEVELOPMENT.md                            # This file — maintenance guide

.apm/
  skills/
    gerador-scaffold-java/
      SKILL.md                            # Workflow definition (5 phases)
      prompts/
        new-java-hexagonal-project.prompt.md    # Interview prompt
      references/
        files-to-adapt.md                 # Token substitution rules
        module-dependencies.md            # Module selection matrix
        readme-template.md                # Dynamic README template
```

### Core Concepts

1. **Template-driven**: All module/capability info comes from `TEMPLATE-MANIFEST.json` (template repo)
2. **Single manifest read**: Read once in Phase 1, reuse throughout
3. **Rules-based adaptation**: Substitution rules defined by file type, not per-file
4. **Remote integration**: Via GitHub MCP, no local clone needed

---

## Critical Files & Why

| File | Why Critical | Breaks If |
|---|---|---|
| `apm.yml` | Declares GitHub MCP as required dependency | Circular deps → install fails; missing required field → APM confused |
| `SKILL.md` | Defines the 5-phase workflow & MCP calls | Wrong instructions → skill fails or generates incorrect code |
| `files-to-adapt.md` | Defines token substitution rules by file type | Wrong rules → tokens left unsubstituted in generated output |
| `module-dependencies.md` | Defines module selection logic | Wrong rules → user selects feature, wrong modules included |
| `TEMPLATE-MANIFEST.json` (in template repo) | Source of truth for modules, capabilities, tokens | Out of sync → skill generates broken projects |

### Safe to Edit

- `README.md` — User setup guide (style, clarity)
- `AGENTS.md` — Global APM guidance (informational)
- `readme-template.md` — Template for generated project READMEs (safe to edit)

---

## Dependencies

### External (Must Be Pre-Configured)

- **GitHub MCP Server**
  - Tool: `get_file_contents`
  - Config: `GITHUB_TOKEN` environment variable
  - Purpose: Read template manifest and module files
  - Status: User must set up before first use
  - Fallback: Skill detects missing config, provides error guidance

### Internal

- **APM Framework** — loads skills from `.apm/` directory
- **Template Repository** — [heandroro/java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)
  - Must have `TEMPLATE-MANIFEST.json` with `capabilities` section
  - See [template PR#1](https://github.com/heandroro/java-hexagonal-template/pull/1) for required structure

---

## When Template Evolves

The skill is **designed to auto-adapt** — no changes needed in most cases.

### Scenario 1: New Module Added

1. Template: Add entry to `TEMPLATE-MANIFEST.json` → modules array
2. Template: Add module files to repo
3. **Skill:** No changes needed — reads manifest at runtime, discovers new module automatically

### Scenario 2: New Token Added

1. Template: Update `TEMPLATE-MANIFEST.json` → replaceTokens section
2. Skill: If token is in existing file type → no change (rule already covers)
3. Skill: If token is in NEW file type → add rule to `files-to-adapt.md`

**Example:** If template adds a new `.properties` file with tokens:
- Add rule to `files-to-adapt.md`: "### Properties files — apply all global tokens"
- No other changes needed

### Scenario 3: New Capability Added

1. Template: Add to `TEMPLATE-MANIFEST.json` → capabilities section
2. Skill: No changes needed — reads capabilities at runtime, generates new interview questions

### Scenario 4: Module Selection Logic Changes

1. Template: Update `TEMPLATE-MANIFEST.json` → module.includeWhen field
2. Skill: No changes needed — reads rules at runtime

---

## When Skill Logic Needs Updating

### Update `SKILL.md` if:

- Interview flow changes (new question, different order)
- User decision tree changes (how modules are selected)
- Token substitution process changes
- Phase descriptions become inaccurate

**Critical:** Do NOT hardcode module lists, capabilities, or file paths in SKILL.md — these must come from `TEMPLATE-MANIFEST.json`.

### Update `files-to-adapt.md` if:

- Substitution rules change by file type
- New file types need adaptation rules
- Token list changes

### Update `apm.yml` if:

- GitHub MCP version changes
- New MCP server dependency added
- Tool names change

### Update `module-dependencies.md` if:

- Inter-module dependency rules change
- Conditional adaptation logic changes (SQS, DynamoDB, Feign)

---

## Common Pitfalls

### 1. Token Phantom — Unsubstituted tokens in generated files

**Cause:** Token defined in `files-to-adapt.md` but doesn't exist in template files.

**Prevention:**
```bash
# Before adding a token rule, grep the template:
grep -r "com.mycompany.template" heandroro/java-hexagonal-template/

# Confirm it exists in at least one file
# Document the file path in files-to-adapt.md
```

### 2. Manifest-Skill Out of Sync

**Cause:** `TEMPLATE-MANIFEST.json` and `files-to-adapt.md` disagree on tokens or file types.

**Prevention:** Keep rules generic (by file type), let manifest provide file-list discovery. Test after template updates.

### 3. Circular Dependencies in apm.yml

**Cause:** Skill listed as a dependency of itself.

**Symptom:** `apm install` fails: "Cannot install packages with circular dependencies"

**Prevention:** Never add this package to its own `dependencies.apm` section.

### 4. Module Conflicts Not Documented

**Cause:** infra-postgres and infra-dynamodb both implement UserRepositoryPort; including both breaks Spring wiring.

**Solution:** Document in `TEMPLATE-MANIFEST.json` → infra-dynamodb.exclusiveWith field. Skill reads this and alerts user.

### 5. GitHub MCP Token Expiry

**Cause:** `GITHUB_TOKEN` in user's settings.json expires.

**Solution:** Skill detects auth failure and provides clear error message directing user to regenerate token.

---

## Testing & Validation

### Quick Test: Does Skill Install?

```bash
apm install --target claude --verbose
# or for any supported target
apm install --target copilot --verbose
```

Expect: No circular dependencies, MCP dependencies listed.

### Full Test: Does Skill Work?

```
1. Start agent in this repo
2. Trigger skill: "criar projeto Java"
3. Complete interview (all phases)
4. Verify generated files in workspace:
   - core/, application/, infra-* modules exist
   - com.mycompany.template NOT in files
   - pom.xml has correct modules
   - Maven builds: mvn clean package
```

### Regression Checklist

After changes, verify:

- [ ] **Install works:** `apm install` completes without errors
- [ ] **MCP detection works:** Missing MCP shows actionable error
- [ ] **Full interview completes:** All phases finish
- [ ] **Generated project builds:** `mvn clean package` succeeds
- [ ] **Tokens substituted:** No `com.mycompany.template` in output
- [ ] **Selective modules:** Different capability choices → correct modules included
- [ ] **Template evolution:** New capability in manifest → skill asks new question
- [ ] **Manifest reading:** Skill reads current manifest, reflects new modules immediately

### Debugging

**Skill fails to read manifest:**
- Verify GitHub MCP configured in user's settings.json
- Verify GITHUB_TOKEN valid and has access to heandroro/java-hexagonal-template
- Verify path correct: `heandroro/java-hexagonal-template/TEMPLATE-MANIFEST.json`

**Generated project won't build:**
- Search generated files for `com.mycompany.template` — if present, token wasn't substituted
- Check pom.xml root module list matches selected modules
- Check application.yml has sections for selected modules

**Skill asks wrong questions:**
- Verify template's `TEMPLATE-MANIFEST.json` → capabilities section is correct
- Verify SKILL.md is parsing and using capabilities correctly

---

## References

- **APM Specification:** https://microsoft.github.io/apm/
- **APM Producer Guidance:** https://microsoft.github.io/apm/producer/
- **Template Repository:** https://github.com/heandroro/java-hexagonal-template
- **Hexagonal Architecture:** "Ports and Adapters" pattern by Alistair Cockburn
