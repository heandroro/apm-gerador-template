# Files to Adapt — Token Substitution Rules

A descoberta dos arquivos a adaptar é feita em tempo de execução a partir do
`TEMPLATE-MANIFEST.json` lido via GitHub MCP. Este arquivo define apenas as
**regras de substituição** por tipo de arquivo — não lista arquivos individualmente.

---

## Token Reference Table

| Token (original) | Substituir por | Contexto |
| --- | --- | --- |
| `com.mycompany.template` | `{NAMESPACE}` | Declaração de pacote, imports Java |
| `com.mycompany` | `{NAMESPACE_ROOT}` | Pacote pai quando NAMESPACE tem profundidade > 2 |
| `java-hexagonal-template` | `{PROJECT_NAME}` | artifactId em pom.xml, nome do repositório |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | Nome do banco PostgreSQL |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Consumer group ID do Kafka |
| `java-hexagonal-template` | `{PROJECT_NAME}` | spring.application.name em application.yml (mesmo token do artifactId) |

---

## Regras por Tipo de Arquivo

### Arquivos `*.java`

- Substituir `com.mycompany.template` por `{NAMESPACE}` em:
  - declaração `package`
  - todos os `import`
  - literais de string que referenciem o pacote
- Renomear o caminho do arquivo:
  `src/main/java/com/mycompany/template/` → `src/main/java/{NAMESPACE_PATH}/`
  onde `{NAMESPACE_PATH}` = `{NAMESPACE}` com `.` substituído por `/`.

### `pom.xml` (raiz e módulos)

- Substituir `java-hexagonal-template` por `{PROJECT_NAME}` (`<artifactId>`, `<name>`).
- Substituir `com.mycompany.template` por `{NAMESPACE}` (`<groupId>`).
- Remover `<module>` do pom.xml raiz para cada módulo excluído.
- Remover `<dependency>` do `application/pom.xml` para cada módulo excluído.

### `application/src/main/resources/application.yml`

- Substituir `java-hexagonal-template` por `{PROJECT_NAME}` (`spring.application.name` — mesmo token do artifactId, já coberto globalmente).
- Substituir `hexagonal_db` por `{PROJECT_NAME_SNAKE}` (nome do datasource/banco).
- Substituir `hexagonal-template-group` por `{PROJECT_NAME}-group` (kafka consumer group).
- Remover blocos de configuração dos serviços de infra excluídos
  (ex: remover bloco `spring.kafka` se não usar Kafka).

### `docker-compose.yml`

Manter apenas os serviços requeridos pelos módulos selecionados:

| Serviço | Manter quando |
| --- | --- |
| `postgres` | `DATABASE = postgres` ou `both` |
| `dynamodb-local` | `DATABASE = dynamodb` ou `both` |
| `redis` / `valkey` | `CACHE = server` |
| `kafka` + `zookeeper` | `APP_TYPE = worker` e `WORKER_BROKER = kafka` |

Remover todos os outros serviços.

### `README.md`

Substituir o arquivo inteiro pelo conteúdo de `./readme-template.md` renderizado
com as variáveis do projeto e capacidades selecionadas.

### `AGENT.md`

- Substituir `java-hexagonal-template` por `{PROJECT_NAME}`.
- Substituir `com.mycompany.template` por `{NAMESPACE}`.
- Atualizar a seção "Project Overview" com `{PROJECT_DESCRIPTION}`.

### `TEMPLATE-MANIFEST.json`

- Substituir `java-hexagonal-template` por `{PROJECT_NAME}`.
- Substituir `com.mycompany.template` por `{NAMESPACE}`.
- Substituir `hexagonal_db` por `{PROJECT_NAME_SNAKE}`.
- Remover entradas do array `modules` referentes a módulos excluídos.

---

## Regra de Renomeação de Caminho de Pacote

Todos os arquivos sob:
```
src/main/java/com/mycompany/template/...
src/test/java/com/mycompany/template/...
```

Devem ser gerados sob o caminho derivado de `{NAMESPACE}`:
- Converter `{NAMESPACE}` trocando `.` por `/`
- Resultado: `src/main/java/{NAMESPACE_PATH}/...`

Exemplo: `NAMESPACE = com.example.payment` → caminho: `com/example/payment`

---

## Adaptações Condicionais

### SQS (quando `WORKER_BROKER = sqs`)

Em `UserEventListener.java` do módulo de mensageria:
- Substituir `@KafkaListener(topics = "...")` por `@SqsListener("${aws.sqs.queue-url}")`
- No `pom.xml` do módulo: substituir dependência `spring-kafka` por `spring-cloud-aws-starter-sqs`

### DynamoDB (quando `DATABASE = dynamodb` ou `both`)

No `pom.xml` raiz: garantir que o BOM/import do AWS SDK esteja presente.

### OpenFeign (quando `HTTP_CLIENT = feign`)

No `pom.xml` raiz: garantir que o BOM/import do Spring Cloud esteja presente.
