# Module Dependencies — Maven Coordinates per Module

This document lists the Maven `<dependency>` blocks to add to `application/pom.xml`
for each infrastructure module, and the dependencies declared in each module's own `pom.xml`.

Use this as a reference when assembling `application/pom.xml` after module selection.

---

## `application/pom.xml` — Inter-module Dependencies

Add one block per included module:

### core (always included)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

### infra-api (if APP_TYPE = api)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-api</artifactId>
    <version>${project.version}</version>
</dependency>
```

### infra-kafka (if messaging enabled)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-kafka</artifactId>
    <version>${project.version}</version>
</dependency>
```

### infra-postgres (if DATABASE = postgres or both)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-postgres</artifactId>
    <version>${project.version}</version>
</dependency>
```

### infra-valkey (if CACHE = server)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-valkey</artifactId>
    <version>${project.version}</version>
</dependency>
```

### infra-dynamodb (if DATABASE = dynamodb or both)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-dynamodb</artifactId>
    <version>${project.version}</version>
</dependency>
```

### infra-client-api (if HTTP_CLIENT = feign)
```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-client-api</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## `infra-api/pom.xml` — External Dependencies

```xml
<!-- Spring Web MVC -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<!-- Validation (Bean Validation / Hibernate Validator) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>

<!-- MapStruct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>

<!-- SpringDoc OpenAPI (optional, recommended) -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
</dependency>

<!-- core module -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## `infra-kafka/pom.xml` — External Dependencies

```xml
<!-- Spring Kafka -->
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>

<!-- MapStruct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>

<!-- core module -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

**If WORKER_BROKER = sqs**, replace `spring-kafka` with:
```xml
<!-- Spring Cloud AWS SQS -->
<dependency>
    <groupId>io.awspring.cloud</groupId>
    <artifactId>spring-cloud-aws-starter-sqs</artifactId>
</dependency>
```

And add to parent `pom.xml` BOM section:
```xml
<dependency>
    <groupId>io.awspring.cloud</groupId>
    <artifactId>spring-cloud-aws-dependencies</artifactId>
    <version>3.0.4</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
```

---

## `infra-postgres/pom.xml` — External Dependencies

```xml
<!-- Spring Data JPA -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<!-- PostgreSQL Driver -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- MapStruct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>

<!-- Lombok (only module where Lombok is permitted) -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>

<!-- core module -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## `infra-valkey/pom.xml` — External Dependencies

```xml
<!-- Spring Data Redis (Valkey is Redis-compatible) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- MapStruct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>

<!-- core module -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## `infra-dynamodb/pom.xml` — External Dependencies

```xml
<!-- AWS SDK v2 DynamoDB Enhanced Client -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>dynamodb-enhanced</artifactId>
</dependency>

<!-- MapStruct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>

<!-- core module -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

Requires in parent `pom.xml` BOM:
```xml
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>bom</artifactId>
    <version>2.25.69</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
```

---

## `infra-client-api/pom.xml` — External Dependencies

```xml
<!-- Spring Cloud OpenFeign -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>

<!-- MapStruct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>

<!-- core module -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
</dependency>
```

Requires in parent `pom.xml` BOM:
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-dependencies</artifactId>
    <version>2023.0.3</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
```

---

## `core/pom.xml` — External Dependencies

```xml
<!-- ONLY permitted external dependency in core -->
<dependency>
    <groupId>jakarta.inject</groupId>
    <artifactId>jakarta.inject-api</artifactId>
    <version>2.0.1</version>
</dependency>
```

---

## Testing Dependencies (declared in parent `pom.xml` `<dependencyManagement>`)

```xml
<!-- JUnit 5 (via Spring Boot Test) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>

<!-- Instancio — test data generation -->
<dependency>
    <groupId>org.instancio</groupId>
    <artifactId>instancio-junit</artifactId>
    <version>4.4.0</version>
    <scope>test</scope>
</dependency>

<!-- AssertJ (included via spring-boot-starter-test) -->

<!-- Testcontainers (optional, add per module) -->
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
```
