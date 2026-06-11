# Files to Adapt — Structural Substitution Rules

File discovery is performed at runtime from the
`TEMPLATE-MANIFEST.json` read via GitHub MCP. This file defines only the
**structural substitution rules** per file type.

**Tokens are not defined here.** The generator reads `TEMPLATE-MANIFEST.json.replaceTokens[]`
from the template itself to obtain the authoritative list of tokens and their descriptions.
This file covers only the **how** to apply substitutions for each file type.

**Docker services are not defined here.** The generator reads `selectedDockerServices[]`
consolidated from the options in `GENERATOR.json.questions[].options[].dockerServices`
(or `profiles[].dockerServices[]`) to determine which services to keep in the compose file.

---

## Rules by File Type

### `*.java` files

- Replace the base package token in:
  - `package` declaration
  - all `import` statements
  - string literals that reference the package
- Rename the file path:
  `src/main/java/com/mycompany/template/` → `src/main/java/{NAMESPACE_PATH}/`
  where `{NAMESPACE_PATH}` = `{NAMESPACE}` with `.` replaced by `/`.

### `pom.xml` (root and modules)

- Replace the artifactId token with the project name (`<artifactId>`, `<name>`).
- Replace the groupId token with the namespace (`<groupId>`).
- Remove `<module>app/{module}</module>` from the root pom.xml for each excluded module.
- Remove `<dependency>` from `app/application/pom.xml` for each excluded module.

### `app/application/src/main/resources/application.yml`

- Replace the application name token (`spring.application.name`).
- Replace the database name token (datasource/db).
- Replace the Kafka consumer group token.
- Replace SQS queue and SNS topic tokens — only if the corresponding modules were selected.
- Remove configuration blocks for excluded infra services
  (e.g.: remove the `spring.kafka` block if Kafka is not used; remove `spring.cloud.aws.sqs`
  if SQS is not used).
- The file contains `spring.docker.compose.file: infra/local/docker-compose.yml` —
  keep this path intact.

### `infra/local/docker-compose.yml`

The file is located at `infra/local/docker-compose.yml` (not at the project root).

Keep only the services present in `selectedDockerServices[]`
(consolidated from the template files via `GENERATOR.json`).

Remove all other services and their corresponding volumes.

### `README.md`

Replace the entire file with the content of `./readme-template.md` rendered
with the project variables and selected capabilities.

### `AGENTS.md`

- Replace the project name token.
- Replace the namespace/base package token.
- Update the "Project Overview" section with `{PROJECT_DESCRIPTION}`.

### `TEMPLATE-MANIFEST.json`

- Replace the project name, namespace, and database name tokens.
- Remove entries from the `modules` array for excluded modules.

---

## Package Path Rename Rule

All files under:
```
src/main/java/com/mycompany/template/...
src/test/java/com/mycompany/template/...
```

Must be generated under the path derived from `{NAMESPACE}`:
- Convert `{NAMESPACE}` replacing `.` with `/`
- Result: `src/main/java/{NAMESPACE_PATH}/...`

Example: `NAMESPACE = com.example.payment` → path: `com/example/payment`

---

## Conditional Adaptations

### SQS (`infra-sqs` selected)

Include the `infra-sqs` module as-is — it already contains `@SqsListener`, publisher, and `NoOp` fallback.
Do not adapt `infra-kafka` for SQS: they are independent modules in the template.
Apply the SQS queue token substitution.

### SNS (`infra-sns` selected)

Include the `infra-sns` module as-is — it already contains publisher and `NoOp` fallback.
Apply the SNS topic token substitution.

### MariaDB (`infra-mariadb` selected)

Include `infra-mariadb` instead of `infra-postgres`. Both implement the same interface
(`UserRepositoryPort`) — they are mutually exclusive.
The file `app/application/src/main/resources/application-mariadb.yml` contains the datasource
overrides. Activate the `mariadb` profile when running the application.

### DynamoDB (`infra-dynamodb` selected)

Include `infra-dynamodb`. Apply the DynamoDB table token substitution.
In the root `pom.xml`: ensure the AWS SDK BOM/import is present (already included in the template).

### OpenFeign (`infra-client-api` selected)

Include `infra-client-api`.
In the root `pom.xml`: ensure the Spring Cloud BOM/import is present (already included in the template).
