# apm-gerador-template

APM package for scaffolding Java Hexagonal Architecture projects from the
[java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template).

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
in your workspace using the template data read through GitHub MCP.

No commit or push happens automatically in this flow.

### Option 2 — Prompt (bundled inside the skill package)

The prompt template is now bundled as a skill asset at:

```text
.apm/skills/gerador-scaffold-java/prompts/new-java-hexagonal-project.prompt.md
```

## What gets generated

| Module | Included when |
| --- | --- |
| `core` | Always |
| `application` | Always |
| `infra-api` | `app_type = api` |
| `infra-kafka` | `app_type = worker`, broker = `kafka` |
| `infra-postgres` | `database = postgres` or `both` |
| `infra-dynamodb` | `database = dynamodb` or `both` |
| `infra-valkey` | `cache = server` |
| `infra-client-api` | `http_client = feign` |

All files are adapted with token substitution and written locally. See the skill documentation for the complete token reference.

## Template source

[heandroro/java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)
