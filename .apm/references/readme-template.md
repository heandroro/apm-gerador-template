# README Template — New Java Hexagonal Project

Use this template to generate the `README.md` for the new project.
Replace all `{VARIABLE}` placeholders with values collected during the interview.

---

```markdown
# {PROJECT_NAME}

> {PROJECT_DESCRIPTION}

## Architecture

This project follows **Hexagonal Architecture** (Ports & Adapters), structured as a Maven
multi-module project with strict layer isolation.

```
{PROJECT_NAME}/
├── core/                    # Business logic — zero framework dependencies
│   ├── domain/              # Domain entities (Java records)
│   ├── ports/in/            # Inbound port interfaces (use cases)
│   ├── ports/out/           # Outbound port interfaces (repository, cache, etc.)
│   └── usecase/             # Use case implementations (@Named)
├── infra-api/               # REST inbound adapter (Spring Web MVC)       [if api]
├── infra-kafka/             # Kafka/SQS inbound adapter                   [if messaging]
├── infra-postgres/          # JPA outbound adapter (PostgreSQL)            [if postgres]
├── infra-valkey/            # Redis/Valkey cache adapter                   [if cache]
├── infra-dynamodb/          # DynamoDB outbound adapter                    [if dynamodb]
├── infra-client-api/        # OpenFeign HTTP client adapter                [if feign]
└── application/             # Spring Boot bootstrap + config
```

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Java {JAVA_VERSION} |
| Framework | Spring Boot 3.5 |
| Build | Maven (multi-module) |
{DATABASE_ROW}
{CACHE_ROW}
{MESSAGING_ROW}
{HTTP_CLIENT_ROW}
| Bean Mapping | MapStruct 1.6 |
| Testing | JUnit 5, Instancio, AssertJ |

## Running Locally

### Prerequisites
- Java {JAVA_VERSION}+
- Maven 3.9+
- Docker & Docker Compose

### Start infrastructure

```bash
docker compose up -d
```

### Run the application

```bash
./mvnw spring-boot:run -pl application
```

### Run tests

```bash
./mvnw verify
```

## Module Dependency Graph

```
application
    └── depends on all infra-* modules
infra-api / infra-kafka / infra-postgres / infra-valkey / infra-dynamodb / infra-client-api
    └── depends on core
core
    └── no external dependencies (only jakarta.inject-api)
```

## Key Conventions

- **`core`** module must never import Spring, JPA, Kafka, or any infrastructure framework.
- Use `@Named` (jakarta.inject) instead of `@Component` or `@Service` in `core`.
- All inbound adapters (controllers, listeners) depend on `core` ports — never on other adapters.
- All outbound adapters implement `core` port interfaces.
- MapStruct mappers use `componentModel = "spring"` in all `infra-*` modules.
- Lombok is only permitted in `infra-postgres`.

## Generated from

This project was scaffolded from [java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)
using the [apm-gerador-template](https://github.com/heandroro/apm-gerador-template) APM package.
```

---

## Variable Reference

| Variable | Description | Example |
|---|---|---|
| `{PROJECT_NAME}` | Artifact ID / repository name | `payment-service` |
| `{PROJECT_DESCRIPTION}` | One-line description | `Serviço de pagamentos PIX` |
| `{JAVA_VERSION}` | `21` or `17` | `21` |
| `{DATABASE_ROW}` | Markdown table row for DB | `\| Database \| PostgreSQL 16 \|` |
| `{CACHE_ROW}` | Markdown table row for cache | `\| Cache \| Valkey (Redis) \|` |
| `{MESSAGING_ROW}` | Markdown table row for messaging | `\| Messaging \| Apache Kafka \|` |
| `{HTTP_CLIENT_ROW}` | Markdown table row for HTTP client | `\| HTTP Client \| OpenFeign \|` |

### Row templates by configuration

**`{DATABASE_ROW}`:**
- `postgres`: `| Database | PostgreSQL 16 (JPA/Hibernate) |`
- `dynamodb`: `| Database | DynamoDB (AWS SDK v2 Enhanced) |`
- `both`: `| Database | PostgreSQL 16 + DynamoDB |`
- `none`: _(empty string — omit row)_

**`{CACHE_ROW}`:**
- `server`: `| Cache | Valkey / Redis (Spring Data Redis) |`
- `local`: `| Cache | Caffeine (in-process) |`
- `none`: _(empty string — omit row)_

**`{MESSAGING_ROW}`:**
- `kafka`: `| Messaging | Apache Kafka (Spring Kafka) |`
- `sqs`: `| Messaging | Amazon SQS (Spring Cloud AWS) |`
- _(not a worker)_: _(empty string — omit row)_

**`{HTTP_CLIENT_ROW}`:**
- `feign`: `| HTTP Client | OpenFeign (Spring Cloud) |`
- `none`: _(empty string — omit row)_
