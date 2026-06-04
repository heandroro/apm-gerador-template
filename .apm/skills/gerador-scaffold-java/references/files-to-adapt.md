# Files to Adapt — Token Substitution Map

This document lists every file from `heandroro/java-hexagonal-template` that requires
token substitution, with the exact tokens per file.

---

## Token Reference Table

| Token (original) | Replaced by | Notes |
| --- | --- | --- |
| `com.mycompany.template` | `{NAMESPACE}` | Java package declaration, import statements |
| `com.mycompany` | `{NAMESPACE_ROOT}` | Parent package when `NAMESPACE` has depth > 2 |
| `java-hexagonal-template` | `{PROJECT_NAME}` | artifactId in pom.xml, repository name |
| `JavaHexagonalTemplate` | `{PROJECT_CLASS_PREFIX}` | PascalCase class name prefix |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | PostgreSQL database name |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Kafka consumer group ID |
| `my-service` | `{PROJECT_NAME}` | Spring application name in application.yml |

---

## Root Files

### `pom.xml`

Tokens:

- `java-hexagonal-template` → `{PROJECT_NAME}` (artifactId, line ~5)
- `com.mycompany.template` → `{NAMESPACE}` (groupId, line ~4)
- Each `<module>` entry for excluded modules → **remove entire `<module>` line**

### `docker-compose.yml`

Action: Keep only services required by selected modules:

- `postgres` service: keep if `DATABASE = postgres` or `both`
- `dynamodb-local` service: keep if `DATABASE = dynamodb` or `both`
- `redis`/`valkey` service: keep if `CACHE = server`
- `kafka` + `zookeeper` services: keep if `APP_TYPE = worker` and `WORKER_BROKER = kafka`
- Remove all others

### `README.md`

Replace entire file with `./readme-template.md` rendered with project variables
and dynamic capability/profile variables (selected modules, stack rows, runtime config,
module tree, dependency graph, and next steps).

### `AGENT.md`

Tokens:

- `java-hexagonal-template` → `{PROJECT_NAME}`
- `com.mycompany.template` → `{NAMESPACE}`
- Update "Project Overview" section with `{PROJECT_DESCRIPTION}`

### `TEMPLATE-MANIFEST.json`

Tokens:

- `java-hexagonal-template` → `{PROJECT_NAME}`
- `com.mycompany.template` → `{NAMESPACE}`
- `hexagonal_db` → `{PROJECT_NAME_SNAKE}`
- Remove entries for excluded modules from `modules` array

---

## Module: `core/`

### `core/pom.xml`

Tokens:

- `java-hexagonal-template` → `{PROJECT_NAME}` (parent artifactId ref)
- `com.mycompany.template` → `{NAMESPACE}` (groupId)

### `core/src/main/java/com/mycompany/template/core/domain/User.java`

File path rename: `com/mycompany/template` → namespace path (e.g. `com/example/payment`)

Tokens:

- `package com.mycompany.template.core.domain;` → `package {NAMESPACE}.core.domain;`
- Class/record name: `User` — keep as-is (domain entity stays named User in template context)

### `core/src/main/java/com/mycompany/template/core/ports/in/CreateUserUseCase.java`

File path rename + package declaration.

### `core/src/main/java/com/mycompany/template/core/ports/in/FindUserUseCase.java`

File path rename + package declaration.

### `core/src/main/java/com/mycompany/template/core/ports/out/UserRepositoryPort.java`

File path rename + package declaration.

### `core/src/main/java/com/mycompany/template/core/ports/out/UserCachePort.java`

File path rename + package declaration. **Include only if `CACHE != none`.**

### `core/src/main/java/com/mycompany/template/core/usecase/CreateUserUseCaseImpl.java`

File path rename + package declaration + all import statements.

Tokens in body:

- `com.mycompany.template.core` → `{NAMESPACE}.core`

### `core/src/main/java/com/mycompany/template/core/usecase/FindUserUseCaseImpl.java`

Same as above.

### Test files under `core/src/test/`

Same package renaming rule applies to all test files.

---

## Module: `application/`

### `application/pom.xml`

Tokens:

- `java-hexagonal-template` → `{PROJECT_NAME}`
- `com.mycompany.template` → `{NAMESPACE}`
- Remove `<dependency>` blocks for excluded modules

### `application/src/main/java/com/mycompany/template/application/Application.java`

File path rename + package declaration.

Tokens:

- `package com.mycompany.template.application;` → `package {NAMESPACE}.application;`

### `application/src/main/resources/application.yml`

Tokens:

- `my-service` → `{PROJECT_NAME}` (spring.application.name)
- `hexagonal_db` → `{PROJECT_NAME_SNAKE}` (datasource database name)
- `hexagonal-template-group` → `{PROJECT_NAME}-group` (kafka consumer group)
- Remove config blocks for excluded infrastructure (e.g. remove `spring.kafka` if no Kafka)

---

## Module: `infra-api/` (include if `APP_TYPE = api`)

### `infra-api/pom.xml`

Tokens: `java-hexagonal-template` → `{PROJECT_NAME}`, `com.mycompany.template` → `{NAMESPACE}`

### All Java files under `infra-api/src/`

File path rename + package declarations + imports.

Class name prefix substitutions:

- `UserController` → use as-is (template entity)
- Import paths: `com.mycompany.template.infra.api` → `{NAMESPACE}.infra.api`
- Import paths: `com.mycompany.template.core` → `{NAMESPACE}.core`

---

## Module: `infra-kafka/` (include if messaging enabled)

### `infra-kafka/pom.xml`

Tokens: standard pom tokens.

### All Java files under `infra-kafka/src/`

File path rename + package declarations + imports.

- Import paths: `com.mycompany.template.infra.kafka` → `{NAMESPACE}.infra.kafka`
- Import paths: `com.mycompany.template.core` → `{NAMESPACE}.core`

### If `WORKER_BROKER = sqs` (adaptation)

In `UserEventListener.java`:

- Replace `@KafkaListener(topics = "...")` with `@SqsListener("${aws.sqs.queue-url}")`
- Replace `spring-kafka` dependency with `spring-cloud-aws-starter-sqs` in pom.xml

---

## Module: `infra-postgres/` (include if `DATABASE = postgres` or `both`)

### `infra-postgres/pom.xml`

Tokens: standard pom tokens.

### All Java files under `infra-postgres/src/`

File path rename + package declarations + imports.

- Import paths: `com.mycompany.template.infra.postgres` → `{NAMESPACE}.infra.postgres`
- Import paths: `com.mycompany.template.core` → `{NAMESPACE}.core`

---

## Module: `infra-valkey/` (include if `CACHE = server`)

### `infra-valkey/pom.xml`

Tokens: standard pom tokens.

### All Java files under `infra-valkey/src/`

File path rename + package declarations + imports.

- Import paths: `com.mycompany.template.infra.valkey` → `{NAMESPACE}.infra.valkey`
- Import paths: `com.mycompany.template.core` → `{NAMESPACE}.core`

---

## Module: `infra-dynamodb/` (include if `DATABASE = dynamodb` or `both`)

### `infra-dynamodb/pom.xml`

Tokens: standard pom tokens.

### All Java files under `infra-dynamodb/src/`

File path rename + package declarations + imports.

---

## Module: `infra-client-api/` (include if `HTTP_CLIENT = feign`)

### `infra-client-api/pom.xml`

Tokens: standard pom tokens.

### All Java files under `infra-client-api/src/`

File path rename + package declarations + imports.

---

## File Path Renaming Rule

All files under:

```text
src/main/java/com/mycompany/template/...
src/test/java/com/mycompany/template/...
```

Must be uploaded to the new repository under the path derived from `{NAMESPACE}`:

```text
com.example.payment-service
  → src/main/java/com/example/paymentservice/...
```

Convert `{NAMESPACE}` dots to `/` to build the directory path.
Strip hyphens from the last segment if present (e.g. `payment-service` → `paymentservice`).
