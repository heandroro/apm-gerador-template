# Arquivos a Adaptar — Mapa de Tokens por Arquivo

Este arquivo lista todos os arquivos do template que contêm tokens a substituir,
com a localização exata de cada ocorrência.

## Tokens de substituição

| Token original | Substituto | Contexto |
|---|---|---|
| `com.mycompany.template` | `{NAMESPACE}` | groupId Maven, pacotes Java |
| `java-hexagonal-template` | `{PROJECT_NAME}` | artifactId, nome de pasta, links |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | nome do banco Postgres |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Kafka consumer group |
| `Hexagonal Architecture multi-module Maven template` | `{PROJECT_DESCRIPTION}` | Descrição no README/pom |

---

## pom.xml (raiz)

Tokens: `com.mycompany.template` (groupId), `java-hexagonal-template` (artifactId, name)

Remover `<module>` para cada módulo não utilizado:
- `<module>infra-api</module>` — se APP_TYPE != api
- `<module>infra-kafka</module>` — se worker broker != kafka e HTTP_CLIENT != feign
- `<module>infra-postgres</module>` — se DATABASE != postgres e != both
- `<module>infra-dynamodb</module>` — se DATABASE != dynamodb e != both
- `<module>infra-valkey</module>` — se CACHE != server
- `<module>infra-client-api</module>` — se HTTP_CLIENT != feign

---

## core/pom.xml

Tokens: `com.mycompany.template` (groupId, parent groupId), `java-hexagonal-template` (parent artifactId)

---

## core/src/main/java — Estrutura de pacotes

Renomear pasta:
```
src/main/java/com/mycompany/template/
          ↓
src/main/java/{NAMESPACE_PATH}/
```
Onde `{NAMESPACE_PATH}` = NAMESPACE com `.` trocado por `/`
(ex: `com.minhaempresa.pagamentos` → `com/minhaempresa/pagamentos`)

Atualizar declaração `package` em todos os arquivos `.java`:
```java
package com.mycompany.template.core.domain;
    ↓
package {NAMESPACE}.core.domain;
```

---

## infra-api/pom.xml

Tokens: `com.mycompany.template` (groupId, parent groupId, dependency groupId), `java-hexagonal-template`

---

## infra-api/src/main/java — Pacotes

Mesma lógica de renomeação de pastas e `package` declarations.

---

## infra-postgres/pom.xml

Tokens: `com.mycompany.template`, `java-hexagonal-template`

---

## infra-valkey/pom.xml

Tokens: `com.mycompany.template`, `java-hexagonal-template`

---

## infra-kafka/pom.xml

Tokens: `com.mycompany.template`, `java-hexagonal-template`

---

## infra-dynamodb/pom.xml

Tokens: `com.mycompany.template`, `java-hexagonal-template`

---

## infra-client-api/pom.xml

Tokens: `com.mycompany.template`, `java-hexagonal-template`

---

## application/pom.xml

Tokens: `com.mycompany.template`, `java-hexagonal-template`

Remover `<dependency>` para cada módulo não utilizado (mesma lógica do pom.xml raiz).

---

## application/src/main/resources/application.yml

Tokens e blocos a adaptar:

```yaml
# Nome da aplicação
spring.application.name: java-hexagonal-template
  ↓
spring.application.name: {PROJECT_NAME}

# Banco de dados PostgreSQL — REMOVER se DATABASE != postgres
spring.datasource.url: jdbc:postgresql://localhost:5432/hexagonal_db
                                                         ↑
                                               substituir por {PROJECT_NAME_SNAKE}

# Kafka consumer group — REMOVER se APP_TYPE != worker (kafka)
spring.kafka.consumer.group-id: hexagonal-template-group
  ↓
spring.kafka.consumer.group-id: {PROJECT_NAME}-group
```

Blocos a remover conforme escolhas:
- Todo bloco `spring.datasource.*` e `spring.jpa.*` → se DATABASE = none ou dynamodb
- Todo bloco `spring.data.redis.*` → se CACHE != server
- Todo bloco `spring.kafka.*` → se APP_TYPE = api e HTTP_CLIENT = feign apenas
- Todo bloco `app.kafka.*` → se APP_TYPE != worker (kafka)
- Todo bloco `app.cache.*` → se CACHE = none
- Perfil `dynamodb` → se DATABASE != dynamodb e != both

---

## docker-compose.yml

Serviços a manter conforme escolhas:

| Serviço | Manter quando |
|---|---|
| `postgres` | DATABASE = postgres ou both |
| `dynamodb-local` | DATABASE = dynamodb ou both |
| `valkey` | CACHE = server |
| `kafka` + `zookeeper` | APP_TYPE = worker (kafka) ou sempre (para dev) |

---

## README.md

Usar template em `/references/readme-template.md`.
Substituir todas as variáveis `{NAMESPACE}`, `{PROJECT_NAME}`, `{PROJECT_DESCRIPTION}`,
e listar apenas os módulos efetivamente incluídos na seção de estrutura.

---

## AGENT.md

Atualizar o cabeçalho para contextualizar o projeto específico:
- Substituir `java-hexagonal-template` pelo `{PROJECT_NAME}`
- Atualizar a descrição na introdução
- Manter todas as regras arquiteturais intactas (elas são universais)

---

## .gitignore

Copiar sem alterações.
