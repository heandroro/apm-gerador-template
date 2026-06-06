# Module Dependencies — Structural Format Rules

Este arquivo define as **regras de formato estrutural** que o gerador precisa para montar
as entradas Maven corretas no projeto gerado.

**Seleção de módulos não é feita aqui.** O gerador lê `GENERATOR.json.questions[].options[].modules`
(e `profiles[].modules[]`) do próprio template para determinar quais módulos incluir, e usa
`GENERATOR.json.postSetup.mutuallyExclusive` para validar exclusividade mútua.
Este arquivo cobre apenas o **como** inserir as entradas no pom.xml.

---

## 1) `app/application/pom.xml` — Dependências Inter-módulo

Após selecionar os módulos, `app/application/pom.xml` deve depender de todos os módulos
selecionados usando `{NAMESPACE}` e `${project.version}`.

Regras mínimas:

- Sempre incluir `core`
- Incluir cada `infra-*` selecionado
- Remover `<dependency>` de todos os módulos excluídos

Formato de entrada:

```xml
<dependency>
    <groupId>{NAMESPACE}</groupId>
    <artifactId>{MODULE_NAME}</artifactId>
    <version>${project.version}</version>
</dependency>
```

---

## 2) `pom.xml` Raiz — Lista de Módulos

Manter `<module>` apenas para módulos selecionados. Os módulos ficam sob `app/`.

Regras:

- Sempre manter `app/core` e `app/application`
- Manter os `app/infra-*` selecionados
- Remover linhas `<module>` dos módulos excluídos

Formato de entrada:

```xml
<module>app/core</module>
<module>app/infra-api</module>
<module>app/application</module>
```

---

## 3) Adaptações que Afetam a Geração

As condições de ativação de cada adaptação são lidas de `GENERATOR.json.questions[].options[]`.
As ações estruturais abaixo são aplicadas pelo gerador quando o módulo correspondente é selecionado.

### SQS (`infra-sqs` selecionado)

- Incluir `infra-sqs` como está — já contém `@SqsListener`, publisher e `NoOp` fallback
- Ativar `@Profile("sqs")` na configuração Spring
- `spring-cloud-aws-dependencies` BOM já está no pom.xml raiz do template

### SNS (`infra-sns` selecionado)

- Incluir `infra-sns` como está — já contém publisher e `NoOp` fallback
- Ativar `@Profile("sns")` na configuração Spring
- `localstack` cobre tanto SQS quanto SNS — adicionar uma única vez mesmo se ambos selecionados

### MariaDB (`infra-mariadb` selecionado)

- Incluir `infra-mariadb` em vez de `infra-postgres` (são mutuamente exclusivos)
- Ativar `@Profile("mariadb")` na configuração Spring
- Usar `application-mariadb.yml` para overrides do datasource

### DynamoDB (`infra-dynamodb` selecionado)

- Incluir `infra-dynamodb`
- Ativar `@Profile("dynamodb")` na configuração Spring
- `spring-cloud-aws-dependencies` BOM já está no pom.xml raiz do template

### OpenFeign (`infra-client-api` selecionado)

- Incluir `infra-client-api`
- Spring Cloud BOM já está incluído no pom.xml raiz do template
- Adicionar serviço `wiremock` ao docker-compose para mock HTTP local

---

## 4) Escopo deste Arquivo

Manter este arquivo focado apenas em:

- Formato de entradas `<module>` e `<dependency>` no pom.xml
- Ações estruturais das adaptações condicionais

Não adicionar aqui:

- Qual módulo incluir para qual capacidade (→ `GENERATOR.json.questions[]`)
- Lista de tokens a substituir (→ `TEMPLATE-MANIFEST.json.replaceTokens[]`)
- Quais serviços docker manter (→ `GENERATOR.json.questions[].options[].dockerServices`)
