# README Template — New Java Hexagonal Project (Dynamic)

Use this template to generate the `README.md` for the new project.
Render all placeholders with values derived from the interview + template capabilities.

---

```markdown
# {PROJECT_NAME}

> {PROJECT_DESCRIPTION}

## Project Profile

| Item | Value |
| --- | --- |
| Namespace | `{NAMESPACE}` |
| App Type | `{APP_TYPE_LABEL}` |
| API Protocol | `{API_PROTOCOL_LABEL}` |
| Worker Broker | `{WORKER_BROKER_LABEL}` |
| Database | `{DATABASE_LABEL}` |
| Cache | `{CACHE_LABEL}` |
| HTTP Client | `{HTTP_CLIENT_LABEL}` |
| Java | `{JAVA_VERSION}` |

## Enabled Modules

{MODULES_SELECTED_LIST}

## Architecture

This project follows **Hexagonal Architecture** (Ports & Adapters), structured as a Maven
multi-module project with strict layer isolation.

```text
{MODULE_TREE}
```

## Tech Stack

| Layer | Technology |
| --- | --- |
| Language | Java {JAVA_VERSION} |
| Framework | Spring Boot {SPRING_BOOT_VERSION} |
| Build | Maven (multi-module) |
{DATABASE_ROW}
{CACHE_ROW}
{MESSAGING_ROW}
{HTTP_CLIENT_ROW}
| Bean Mapping | MapStruct {MAPSTRUCT_VERSION} |
| Testing | JUnit 5, Instancio, AssertJ |

## Running Locally

### Prerequisites
- Java {JAVA_VERSION}+
- Maven 3.9+
{DOCKER_PREREQUISITE_ROW}

### Start infrastructure

```bash
{INFRA_START_COMMAND}
```

### Run application

```bash
{RUN_APPLICATION_COMMAND}
```

### Validate build

```bash
mvn clean compile
mvn test
mvn package
```

## Runtime Configuration

| Variable | Required | Description |
| --- | --- | --- |
{REQUIRED_ENV_VARS_ROWS}

## Module Dependency Graph

```text
{MODULE_DEP_GRAPH}
```

## Key Conventions

- **`core`** must never import Spring, JPA, Kafka, or any infrastructure framework.
- Use `@Named` (jakarta.inject) instead of `@Component` or `@Service` in `core`.
- Inbound adapters depend on `core` ports only.
- Outbound adapters implement `core` port interfaces.
- MapStruct mappers use `componentModel = "spring"` in all `infra-*` modules.
- Lombok is allowed only in `infra-postgres`.

## Next Steps

{NEXT_STEPS_LIST}

## Generated From

This project was scaffolded from [java-hexagonal-template](https://github.com/heandroro/java-hexagonal-template)
using the [apm-gerador-template](https://github.com/heandroro/apm-gerador-template) APM package.

Official APM reference: [microsoft.github.io/apm](https://microsoft.github.io/apm/)
```

---

## Variable Reference

| Variable | Description | Example |
| --- | --- | --- |
| `{PROJECT_NAME}` | Artifact ID / project name | `payment-service` |
| `{PROJECT_DESCRIPTION}` | One-line description | `PIX payment processing service` |
| `{NAMESPACE}` | Maven groupId / base package | `com.example.payments` |
| `{APP_TYPE_LABEL}` | Human label for app type | `API` |
| `{API_PROTOCOL_LABEL}` | Human label for API protocol | `REST` |
| `{WORKER_BROKER_LABEL}` | Human label for broker | `Kafka` |
| `{DATABASE_LABEL}` | Human label for database mode | `PostgreSQL + DynamoDB` |
| `{CACHE_LABEL}` | Human label for cache mode | `Valkey/Redis` |
| `{HTTP_CLIENT_LABEL}` | Human label for client mode | `OpenFeign` |
| `{MODULES_SELECTED_LIST}` | Markdown list of selected modules | `- core\n- application\n- infra-api` |
| `{MODULE_TREE}` | Generated folder tree with selected modules only | `payment-service/...` |
| `{SPRING_BOOT_VERSION}` | Spring Boot version from template | `3.5` |
| `{MAPSTRUCT_VERSION}` | MapStruct version from template | `1.6` |
| `{JAVA_VERSION}` | Java version from template/project | `21` |
| `{DATABASE_ROW}` | Markdown row for DB stack | `| Database | PostgreSQL 16 |` |
| `{CACHE_ROW}` | Markdown row for cache stack | `| Cache | Caffeine |` |
| `{MESSAGING_ROW}` | Markdown row for messaging stack | `| Messaging | Kafka |` |
| `{HTTP_CLIENT_ROW}` | Markdown row for outbound client stack | `| HTTP Client | OpenFeign |` |
| `{DOCKER_PREREQUISITE_ROW}` | Optional prerequisite row for infra | `- Docker & Docker Compose` |
| `{INFRA_START_COMMAND}` | Command to start only required infra services | `docker compose up -d postgres kafka` |
| `{RUN_APPLICATION_COMMAND}` | Command suited to app type | `./mvnw spring-boot:run -pl application` |
| `{REQUIRED_ENV_VARS_ROWS}` | Markdown rows with required env vars | `| DB_URL | Yes | JDBC URL |` |
| `{MODULE_DEP_GRAPH}` | Dependency graph for selected modules | `application -> infra-* -> core` |
| `{NEXT_STEPS_LIST}` | Post-generation checklist | `1. Review generated files ...` |

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

**`{REQUIRED_ENV_VARS_ROWS}`:**
- If no required variables exist: `| _none_ | No | No required variables for current profile. |`

**`{NEXT_STEPS_LIST}` (suggested default):**
1. `Review the generated files and configuration adjustments.`
2. `Start local infrastructure and validate startup.`
3. `Run mvn clean compile, mvn test, and mvn package.`
4. `If everything is OK, consider creating a commit and pushing (with user confirmation).`
