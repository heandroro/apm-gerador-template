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
| `APP_TYPE = api` | `infra-api` | Inbound HTTP adapter |
| `APP_TYPE = worker` and `WORKER_BROKER = kafka` | `infra-kafka` | Messaging adapter |
| `APP_TYPE = worker` and `WORKER_BROKER = sqs` | `infra-kafka` | Generate from kafka base and apply SQS adaptation |
| `DATABASE = postgres` or `both` | `infra-postgres` | PostgreSQL adapter |
| `DATABASE = dynamodb` or `both` | `infra-dynamodb` | DynamoDB adapter |
| `CACHE = server` | `infra-valkey` | Redis/Valkey adapter |
| `HTTP_CLIENT = feign` | `infra-client-api` | Outbound HTTP client adapter |

---

## 2) `application/pom.xml` Inter-module Dependencies

After module selection, `application/pom.xml` must depend on all selected modules
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

Keep `<module>` entries only for selected modules.

Rules:
- Always keep `core` and `application`
- Keep selected `infra-*` modules
- Remove `<module>` lines for excluded modules

---

## 4) Conditional Adaptations That Affect Generation

Apply these only when the related option is selected.

### SQS adaptation
- Trigger: `APP_TYPE = worker` and `WORKER_BROKER = sqs`
- Actions:
  - Replace kafka listener annotation with `@SqsListener`
  - Replace kafka dependency with SQS dependency in the messaging module
  - Ensure required AWS Spring BOM/import is present in parent `pom.xml`

### DynamoDB adaptation
- Trigger: `DATABASE = dynamodb` or `both`
- Actions:
  - Ensure DynamoDB module is included
  - Ensure required AWS SDK BOM/import is present in parent `pom.xml`

### OpenFeign adaptation
- Trigger: `HTTP_CLIENT = feign`
- Actions:
  - Ensure `infra-client-api` module is included
  - Ensure required Spring Cloud BOM/import is present in parent `pom.xml`

---

## 5) Scope of This File

Keep this file focused on generation rules only:
- Which modules to include/exclude
- Which inter-module dependencies to add/remove
- Which conditional adaptations are mandatory

Do not add full dependency catalogs or long XML examples here.
