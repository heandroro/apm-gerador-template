# apm-gerador-template

APM package for scaffolding Java Hexagonal Architecture projects.

**Default template**: [java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)
(Configurable via `TEMPLATE_OWNER` and `TEMPLATE_REPO` environment variables — see [DEVELOPMENT.md](DEVELOPMENT.md))

Official APM references: [microsoft.github.io/apm](https://microsoft.github.io/apm/) (general) and [microsoft.github.io/apm/producer](https://microsoft.github.io/apm/producer/) (producer).

## Install

```bash
apm install heandroro/apm-gerador-template
```

## Setup (Minimal)

The skill uses a **hybrid fetch strategy** for template data:

### Option A: Install gh CLI (Recommended)

**Fastest & most token-efficient approach.**

1. Install: `brew install gh` (macOS) or see [github.com/cli/cli](https://github.com/cli/cli)
2. Authenticate: `gh auth login`
3. Done! The skill auto-detects gh CLI and uses it.

### Option B: Use git (Universal Fallback)

**Works everywhere** — no additional installation needed.

The skill automatically falls back to `git clone` if gh CLI is unavailable.

### Optional: GitHub MCP (For advanced features)

If you need GitHub integration beyond template fetching, configure MCP:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "<your-github-token-here>"
      }
    }
  }
}
```

### Verification

The skill will automatically:
- Try `gh CLI` (primary, ~3-5s, 5K tokens)
- Fall back to `git clone` if gh unavailable (universal, ~30-50MB)
- Work offline with cache hits (~100ms)

## Usage

### Option 1 — Skill (auto-activates)

Just describe what you want. The `gerador-scaffold-java` skill activates automatically
when you say things like:

- _"criar projeto Java"_
- _"novo projeto hexagonal"_
- _"gerar scaffold para microserviço"_
- _"criar repositório com arquitetura hexagonal"_

The skill will interview you, present a summary, and then generate all files locally
in your workspace using template data (fetched via gh CLI or git clone).

No commit or push happens automatically in this flow.

### Option 2 — Prompt (bundled inside the skill package)

The prompt template is now bundled as a skill asset at:

```text
.apm/skills/gerador-scaffold-java/prompts/new-java-hexagonal-project.prompt.md
```

## What gets generated

The skill generates a complete Java Hexagonal Architecture project with:

- **Core modules** (always included): `core`, `application`
- **Infrastructure modules** (conditional): API, database, cache, messaging, etc.
- **Configuration files**: `pom.xml`, `application.yml`, `Dockerfile`, etc.
- **Documentation**: `README.md`, `AGENTS.md`

**Modules included** depend on your choices during the interview (database type, app type, etc.).

For the **complete module list and selection logic**, see:
- [SKILL.md](DEVELOPMENT.md) — Fase 3 (Module Decision)
- Template source: [TEMPLATE-MANIFEST.json](https://github.com/heandroro/java-hexagonal-template/blob/main/TEMPLATE-MANIFEST.json) (source of truth)

All files are adapted with token substitution based on your project name and namespace.

## Template source

**Default**: [heandroro/java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)

**Customizable**: Set `TEMPLATE_OWNER` and `TEMPLATE_REPO` environment variables to use a different template repository (see [DEVELOPMENT.md](DEVELOPMENT.md#template-configuration-centralized))
