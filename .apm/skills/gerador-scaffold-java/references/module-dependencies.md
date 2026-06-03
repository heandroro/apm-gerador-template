# Dependências Maven por Módulo

Use este arquivo como referência ao adaptar os `pom.xml` de cada módulo.
Baseado no TEMPLATE-MANIFEST.json do repositório template.

---

## core/pom.xml

Única dependência permitida:
```xml
<dependency>
    <groupId>jakarta.inject</groupId>
    <artifactId>jakarta.inject-api</artifactId>
</dependency>
```

---

## infra-api/pom.xml

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>
```

---

## infra-postgres/pom.xml

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

---

## infra-valkey/pom.xml

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

---

## infra-kafka/pom.xml

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>
```

---

## infra-dynamodb/pom.xml

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>
<dependency>
    <groupId>io.awspring.cloud</groupId>
    <artifactId>spring-cloud-aws-starter-dynamodb</artifactId>
</dependency>
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
</dependency>
```

---

## infra-client-api/pom.xml

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

---

## application/pom.xml — dependências de módulos

Incluir apenas os módulos selecionados:

```xml
<!-- Sempre incluir -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>core</artifactId>
</dependency>

<!-- Se APP_TYPE = api -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-api</artifactId>
</dependency>

<!-- Se APP_TYPE = worker (kafka) -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-kafka</artifactId>
</dependency>

<!-- Se DATABASE = postgres ou both -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-postgres</artifactId>
</dependency>

<!-- Se DATABASE = dynamodb ou both -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-dynamodb</artifactId>
</dependency>

<!-- Se CACHE = server -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-valkey</artifactId>
</dependency>

<!-- Se HTTP_CLIENT = feign -->
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>infra-client-api</artifactId>
</dependency>

<!-- Sempre incluir -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

---

## Nota sobre SQS (se WORKER_BROKER = sqs)

Substituir dependência do Kafka por:
```xml
<dependency>
    <groupId>io.awspring.cloud</groupId>
    <artifactId>spring-cloud-aws-starter-sqs</artifactId>
</dependency>
```

E adaptar o Listener para usar `@SqsListener` ao invés de `@KafkaListener`.
