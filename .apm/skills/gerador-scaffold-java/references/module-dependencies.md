# Module Dependencies — Rules for Project Generation

This file is intentionally concise. It defines only the rules the generator needs to
decide which modules and inter-module dependencies must exist in the generated project.

Do not duplicate full framework dependency blocks here. Those details belong to the
template repository module `pom.xml` files.

---

## 1) Module Selection Matrix

| Input condition | Include module | Notes |
| --- | --- | --- |
| Always | `core` | Required in every project |
| Always | `application` | Bootstrap and runtime wiring |
| `APP_TYPE = api` | `infra-api` | Inbound REST adapter (Spring Web MVC) |
| `MESSAGING = kafka` | `infra-kafka` | Kafka listener + Avro publisher |
| `MESSAGING = sqs` | `infra-sqs` | Dedicated SQS listener + publisher + NoOp fallback |
| `MESSAGING = sns` | `infra-sns` | Dedicated SNS fan-out publisher + NoOp fallback |
| `DATABASE = postgres` | `infra-postgres` | PostgreSQL adapter (default) |
| `DATABASE = mariadb` | `infra-mariadb` | MariaDB adapter — drop-in for postgres (`@Profile("mariadb")`) |
| `DATABASE = dynamodb` | `infra-dynamodb` | DynamoDB adapter (`@Profile("dynamodb")`) |
| `CACHE = server` | `infra-valkey` | Redis/Valkey adapter |
| `HTTP_CLIENT = feign` | `infra-client-api` | Outbound HTTP client (OpenFeign) |

**Important:** `infra-postgres`, `infra-mariadb`, and `infra-dynamodb` are mutually exclusive —
include at most one persistence adapter. If the user selects more than one, ask them to choose.

`infra-sqs` and `infra-sns` are independent modules and can be included together.
They share the same LocalStack docker service.

---

## 2) `app/application/pom.xml` Inter-module Dependencies

After module selection, `app/application/pom.xml` must depend on all selected modules
using `{NAMESPACE}` and `${project.version}`.

Minimum set:
- Always include `core`
- Include each selected `infra-*` module
- Remove dependencies for all excluded modules

Dependency block pattern:

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>{MODULE_NAME}</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## 3) Parent `pom.xml` Module List

Keep `<module>` entries only for selected modules. Modules live under `app/`.

Rules:
- Always keep `app/core` and `app/application`
- Keep selected `app/infra-*` modules
- Remove `<module>` lines for excluded modules

Example entry format:
```xml
<module>app/core</module>
<module>app/infra-api</module>
<module>app/application</module>
```

---

## 4) Conditional Adaptations That Affect Generation

Apply these only when the related option is selected.

### SQS adaptation
- Trigger: `MESSAGING = sqs`
- Actions:
  - Include `infra-sqs` module as-is — it already has `@SqsListener`, publisher, and `NoOp` fallback
  - Activate `@Profile("sqs")` in Spring configuration
  - Ensure `spring-cloud-aws-dependencies` BOM is present in parent `pom.xml` (already included in template)
  - Add `localstack` service to docker-compose

### SNS adaptation
- Trigger: `MESSAGING = sns`
- Actions:
  - Include `infra-sns` module as-is — it already has publisher and `NoOp` fallback
  - Activate `@Profile("sns")` in Spring configuration
  - `localstack` service covers both SQS and SNS — add it once even if both are selected

### MariaDB adaptation
- Trigger: `DATABASE = mariadb`
- Actions:
  - Include `infra-mariadb` instead of `infra-postgres`
  - Activate `@Profile("mariadb")` in Spring configuration
  - Use `application-mariadb.yml` profile file for datasource overrides

### DynamoDB adaptation
- Trigger: `DATABASE = dynamodb`
- Actions:
  - Include `infra-dynamodb` module
  - Activate `@Profile("dynamodb")` in Spring configuration
  - Ensure `spring-cloud-aws-dependencies` BOM is present in parent `pom.xml` (already included in template)
  - Add `dynamodb-local` service to docker-compose

### OpenFeign adaptation
- Trigger: `HTTP_CLIENT = feign`
- Actions:
  - Include `infra-client-api` module
  - Ensure Spring Cloud BOM/import is present in parent `pom.xml` (already included in template)
  - Add `wiremock` service to docker-compose for local HTTP mocking

---

## 5) Scope of This File

Keep this file focused on generation rules only:
- Which modules to include/exclude
- Which inter-module dependencies to add/remove
- Which conditional adaptations are mandatory

Do not add full dependency catalogs or long XML examples here.
