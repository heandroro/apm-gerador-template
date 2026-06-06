# Files to Adapt — Structural Substitution Rules

A descoberta dos arquivos a adaptar é feita em tempo de execução a partir do
`TEMPLATE-MANIFEST.json` lido via GitHub MCP. Este arquivo define apenas as
**regras estruturais de substituição** por tipo de arquivo.

**Tokens não são definidos aqui.** O gerador lê `TEMPLATE-MANIFEST.json.replaceTokens[]`
do próprio template para obter a lista autoritativa de tokens e suas descrições.
Este arquivo cobre apenas o **como** aplicar as substituições em cada tipo de arquivo.

**Serviços docker não são definidos aqui.** O gerador lê `selectedDockerServices[]`
consolidado das opções em `GENERATOR.json.questions[].options[].dockerServices`
(ou `profiles[].dockerServices[]`) para saber quais serviços manter no compose.

---

## Regras por Tipo de Arquivo

### Arquivos `*.java`

- Substituir o token de pacote base em:
  - declaração `package`
  - todos os `import`
  - literais de string que referenciem o pacote
- Renomear o caminho do arquivo:
  `src/main/java/com/mycompany/template/` → `src/main/java/{NAMESPACE_PATH}/`
  onde `{NAMESPACE_PATH}` = `{NAMESPACE}` com `.` substituído por `/`.

### `pom.xml` (raiz e módulos)

- Substituir o token de artifactId pelo nome do projeto (`<artifactId>`, `<name>`).
- Substituir o token de groupId pelo namespace (`<groupId>`).
- Remover `<module>app/{módulo}</module>` do pom.xml raiz para cada módulo excluído.
- Remover `<dependency>` do `app/application/pom.xml` para cada módulo excluído.

### `app/application/src/main/resources/application.yml`

- Substituir o token de nome da aplicação (`spring.application.name`).
- Substituir o token de nome do banco de dados (datasource/banco).
- Substituir o token de consumer group do Kafka.
- Substituir tokens de fila SQS e tópico SNS — somente se os módulos correspondentes
  foram selecionados.
- Remover blocos de configuração dos serviços de infra excluídos
  (ex: remover bloco `spring.kafka` se não usar Kafka; remover `spring.cloud.aws.sqs`
  se não usar SQS).
- O arquivo contém `spring.docker.compose.file: infra/local/docker-compose.yml` —
  manter este caminho intacto.

### `infra/local/docker-compose.yml`

O arquivo está em `infra/local/docker-compose.yml` (não na raiz do projeto).

Manter apenas os serviços presentes em `selectedDockerServices[]`
(consolidado dos arquivos do template via `GENERATOR.json`).

Remover todos os outros serviços e seus volumes correspondentes.

### `README.md`

Substituir o arquivo inteiro pelo conteúdo de `./readme-template.md` renderizado
com as variáveis do projeto e capacidades selecionadas.

### `AGENTS.md`

- Substituir o token de nome do projeto.
- Substituir o token de namespace/pacote base.
- Atualizar a seção "Project Overview" com `{PROJECT_DESCRIPTION}`.

### `TEMPLATE-MANIFEST.json`

- Substituir os tokens de nome do projeto, namespace e nome do banco.
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

### SQS (`infra-sqs` selecionado)

Incluir o módulo `infra-sqs` como está — ele já contém `@SqsListener`, publisher e fallback `NoOp`.
Não adaptar `infra-kafka` para SQS: são módulos independentes no template.
Aplicar substituição do token de fila SQS.

### SNS (`infra-sns` selecionado)

Incluir o módulo `infra-sns` como está — ele já contém publisher e fallback `NoOp`.
Aplicar substituição do token de tópico SNS.

### MariaDB (`infra-mariadb` selecionado)

Incluir `infra-mariadb` em vez de `infra-postgres`. Os dois implementam a mesma interface
(`UserRepositoryPort`) — são mutuamente exclusivos.
O arquivo `app/application/src/main/resources/application-mariadb.yml` contém as overrides
do datasource. Ativar profile `mariadb` ao rodar a aplicação.

### DynamoDB (`infra-dynamodb` selecionado)

Incluir `infra-dynamodb`. Aplicar substituição do token de tabela DynamoDB.
No `pom.xml` raiz: garantir que o BOM/import do AWS SDK esteja presente (já incluído no template).

### OpenFeign (`infra-client-api` selecionado)

Incluir `infra-client-api`.
No `pom.xml` raiz: garantir que o BOM/import do Spring Cloud esteja presente (já incluído no template).
