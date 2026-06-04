# apm-gerador-template

APM package for scaffolding Java Hexagonal Architecture projects from the
[java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template).

## Install

```bash
apm install heandroro/apm-gerador-template
```

## Requirements

The GitHub MCP server must be connected with a valid `GITHUB_TOKEN` to read template data:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "<your-token>" }
    }
  }
}
```

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

### Option 2 — Prompt (on-demand)

Use `/new-java-hexagonal-project` to fill in all project variables at once:

```text
/new-java-hexagonal-project
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

All files are adapted with token substitution and written locally:

| Template token | Replaced by |
| --- | --- |
| `com.mycompany.template` | Your namespace (groupId) |
| `java-hexagonal-template` | Your project name (artifactId) |
| `JavaHexagonalTemplate` | PascalCase class prefix |
| `hexagonal_db` | Snake-case database name |

## Template source

[heandroro/java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)
