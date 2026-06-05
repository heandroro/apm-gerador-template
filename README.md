# apm-gerador-template

APM package for scaffolding Java Hexagonal Architecture projects from the
[java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template).

Official APM references: [microsoft.github.io/apm](https://microsoft.github.io/apm/) (general) and [microsoft.github.io/apm/producer](https://microsoft.github.io/apm/producer/) (producer).

## Install

```bash
apm install heandroro/apm-gerador-template
```

## Setup (Required)

### 1. Create or get a GitHub personal access token

Generate a token at: https://github.com/settings/tokens

Minimum scopes needed: `public_repo` (read-only access to public repositories)

### 2. Configure GitHub MCP in your Claude Code settings

Add to your `settings.json` or `settings.local.json`:

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

### 3. Verify the setup

The skill will automatically detect if GitHub MCP is configured and ready.

If configuration is missing, the skill will:
- Check if `GITHUB_TOKEN` exists → suggest activating GitHub MCP
- Check if token is missing → suggest both token and MCP setup

No manual verification needed — the skill handles it.

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
