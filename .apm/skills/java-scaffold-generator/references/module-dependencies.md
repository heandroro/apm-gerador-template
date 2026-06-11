# Module Dependencies — Structural Format Rules

This file defines the **structural format rules** the generator needs to assemble
the correct Maven entries in the generated project.

**Module selection is not done here.** The generator reads `GENERATOR.json.questions[].options[].modules`
(and `profiles[].modules[]`) from the template itself to determine which modules to include, and uses
`GENERATOR.json.postSetup.mutuallyExclusive` to validate mutual exclusivity.
This file covers only the **how** to insert entries into the pom.xml.

---

## 1) `app/application/pom.xml` — Inter-module Dependencies

After selecting the modules, `app/application/pom.xml` must depend on all selected modules
using `{NAMESPACE}` and `${project.version}`.

Minimum rules:

- Always include `core`
- Include each selected `infra-*`
- Remove `<dependency>` for all excluded modules

Entry format:

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>{MODULE_NAME}</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## 2) Root `pom.xml` — Module List

Keep `<module>` only for selected modules. Modules live under `app/`.

Rules:

- Always keep `app/core` and `app/application`
- Keep the selected `app/infra-*` modules
- Remove `<module>` lines for excluded modules

Entry format:

```xml
<module>app/core</module>
<module>app/infra-api</module>
<module>app/application</module>
```

---

## 3) Adaptations Affecting Generation

The activation conditions for each adaptation are read from `GENERATOR.json.questions[].options[]`.
The structural actions below are applied by the generator when the corresponding module is selected.

### SQS (`infra-sqs` selected)

- Include `infra-sqs` as-is — already contains `@SqsListener`, publisher, and `NoOp` fallback
- Activate `@Profile("sqs")` in Spring configuration
- `spring-cloud-aws-dependencies` BOM is already in the template's root pom.xml

### SNS (`infra-sns` selected)

- Include `infra-sns` as-is — already contains publisher and `NoOp` fallback
- Activate `@Profile("sns")` in Spring configuration
- `localstack` covers both SQS and SNS — add it only once even if both are selected

### MariaDB (`infra-mariadb` selected)

- Include `infra-mariadb` instead of `infra-postgres` (they are mutually exclusive)
- Activate `@Profile("mariadb")` in Spring configuration
- Use `application-mariadb.yml` for datasource overrides

### DynamoDB (`infra-dynamodb` selected)

- Include `infra-dynamodb`
- Activate `@Profile("dynamodb")` in Spring configuration
- `spring-cloud-aws-dependencies` BOM is already in the template's root pom.xml

### OpenFeign (`infra-client-api` selected)

- Include `infra-client-api`
- Spring Cloud BOM is already included in the template's root pom.xml
- Add `wiremock` service to docker-compose for local HTTP mocking

---

## 4) Scope of This File

Keep this file focused only on:

- Format of `<module>` and `<dependency>` entries in pom.xml
- Structural actions for conditional adaptations

Do not add here:

- Which module to include for which capability (→ `GENERATOR.json.questions[]`)
- List of tokens to substitute (→ `TEMPLATE-MANIFEST.json.replaceTokens[]`)
- Which docker services to keep (→ `GENERATOR.json.questions[].options[].dockerServices`)
