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
| `java-hexagonal-template` | `{PROJECT_NAME}` | artifactId em pom.xml, nome do repositório, spring.application.name |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | Nome do banco PostgreSQL / MariaDB |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Consumer group ID do Kafka |
| `user-events-queue` | `{PROJECT_NAME_SNAKE}-events-queue` | Nome da fila SQS (substituir só se MESSAGING = sqs) |
| `user-events-topic` | `{PROJECT_NAME_SNAKE}-events-topic` | Nome do tópico SNS (substituir só se MESSAGING = sns) |
| `users` | `{ENTITY_NAME_PLURAL}` | Nome da tabela DynamoDB (substituir só se DATABASE = dynamodb) |

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
- Remover `<module>app/{módulo}</module>` do pom.xml raiz para cada módulo excluído.
- Remover `<dependency>` do `app/application/pom.xml` para cada módulo excluído.

### `app/application/src/main/resources/application.yml`

- Substituir `java-hexagonal-template` por `{PROJECT_NAME}` (`spring.application.name`).
- Substituir `hexagonal_db` por `{PROJECT_NAME_SNAKE}` (nome do datasource/banco).
- Substituir `hexagonal-template-group` por `{PROJECT_NAME}-group` (kafka consumer group).
- Substituir `user-events-queue` por `{PROJECT_NAME_SNAKE}-events-queue` (se MESSAGING = sqs).
- Substituir `user-events-topic` por `{PROJECT_NAME_SNAKE}-events-topic` (se MESSAGING = sns).
- Remover blocos de configuração dos serviços de infra excluídos
  (ex: remover bloco `spring.kafka` se não usar Kafka, remover `spring.cloud.aws.sqs` se não usar SQS).

### `infra/local/docker-compose.yml`

O arquivo está em `infra/local/docker-compose.yml` (não na raiz).
Manter apenas os serviços requeridos pelos módulos selecionados:

| Serviço | Manter quando |
| --- | --- |
| `postgres` | `DATABASE = postgres` |
| `mariadb` | `DATABASE = mariadb` |
| `dynamodb-local` + `dynamodb-init` | `DATABASE = dynamodb` |
| `valkey` | `CACHE = server` |
| `kafka` + `schema-registry` | `MESSAGING = kafka` (KRaft — sem Zookeeper) |
| `localstack` + `localstack-init` | `MESSAGING = sqs` e/ou `MESSAGING = sns` |
| `wiremock` | `HTTP_CLIENT = feign` |

Remover todos os outros serviços e seus volumes correspondentes.
O arquivo `app/application/src/main/resources/application.yml` contém
`spring.docker.compose.file: infra/local/docker-compose.yml` — manter este caminho.

### `README.md`

Substituir o arquivo inteiro pelo conteúdo de `./readme-template.md` renderizado
com as variáveis do projeto e capacidades selecionadas.

### `AGENTS.md`

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

### SQS (quando `MESSAGING = sqs`)

Incluir o módulo `infra-sqs` como está — ele já contém `@SqsListener`, publisher e fallback `NoOp`.
Não adaptar `infra-kafka` para SQS: são módulos independentes no template.
Substituir tokens de fila: `user-events-queue` → `{PROJECT_NAME_SNAKE}-events-queue`.

### SNS (quando `MESSAGING = sns`)

Incluir o módulo `infra-sns` como está — ele já contém publisher e fallback `NoOp`.
Substituir tokens de tópico: `user-events-topic` → `{PROJECT_NAME_SNAKE}-events-topic`.

### MariaDB (quando `DATABASE = mariadb`)

Incluir `infra-mariadb` em vez de `infra-postgres`. Os dois têm a mesma interface (`UserRepositoryPort`).
O arquivo `app/application/src/main/resources/application-mariadb.yml` contém as overrides do datasource.
Ativar profile `mariadb` ao rodar a aplicação.

### DynamoDB (quando `DATABASE = dynamodb`)

Incluir `infra-dynamodb`. Substituir token de tabela: `users` → `{ENTITY_NAME_PLURAL}`.
No `pom.xml` raiz: garantir que o BOM/import do AWS SDK esteja presente (já incluído no template).

### OpenFeign (quando `HTTP_CLIENT = feign`)

Incluir `infra-client-api`.
No `pom.xml` raiz: garantir que o BOM/import do Spring Cloud esteja presente (já incluído no template).
