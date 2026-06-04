---
name: gerador-scaffold-java
description: "Use when the user wants to create a new Java project from the hexagonal template (https://github.com/heandroro/java-hexagonal-template). Triggers include: \"criar projeto\", \"novo projeto Java\", \"gerar projeto\", \"scaffolding\", \"criar repositório hexagonal\", \"novo serviço Java\", \"criar microserviço\", or any mention of starting a new Java service based on the hexagonal architecture template. Conducts a structured interview, reads template data via the GitHub MCP, and generates the adapted files locally in the workspace by default. Apply even when the user says only \"quero criar um projeto\" or \"me ajuda a criar um serviço novo\"."
argument-hint: "Opcionalmente informe o nome do projeto ou namespace (ex: payment-service, com.minhaempresa.pagamentos)"
---

# Agent Package Manager — Java Hexagonal Template

Este skill conduz uma entrevista estruturada com o usuário, coleta as decisões de projeto,
usa o GitHub MCP para ler os dados do template e gera os arquivos adaptados localmente
no workspace por padrão.

---

## Pré-requisito: leitura do template via GitHub MCP

Antes de iniciar, verifique se as ferramentas do GitHub MCP estão disponíveis no contexto
(ex: `get_file_contents`).

Se não estiverem:
1. Informe o usuário que a leitura remota do template depende do GitHub MCP.
2. Indique o link: https://github.com/modelcontextprotocol/servers/tree/main/src/github
3. Continue com a geração local usando os arquivos de referência do pacote.

---

## Fase 1 — Entrevista de Projeto

Faça as perguntas abaixo **uma de cada vez**, aguardando a resposta antes de prosseguir.
Use linguagem amigável e exemplos concretos para guiar o usuário.

### Pergunta 1 — Namespace
```
Qual será o namespace (groupId Maven) do projeto?
Exemplo: com.minhaempresa.pagamentos
```
- Valide que seja um pacote Java válido (lowercase, sem hífens, sem espaços).
- Armazene como: `NAMESPACE`

### Pergunta 2 — Nome do Projeto
```
Qual o nome do projeto? (será usado como artifactId Maven e nome do repositório GitHub)
Exemplo: payment-service
```
- Valide: lowercase, hífens permitidos, sem espaços.
- Armazene como: `PROJECT_NAME`
- Derive: `PROJECT_NAME_SNAKE` = PROJECT_NAME com hífens → underscores (para DB name).
- Derive: `PROJECT_CLASS_PREFIX` = PascalCase sem hífens (ex: `PaymentService`) — usado em nomes de classes.

### Pergunta 3 — Descrição
```
Qual a descrição do projeto? (será usada no README.md e no pom.xml)
Exemplo: Serviço responsável por processar pagamentos via PIX e cartão.
```
- Armazene como: `PROJECT_DESCRIPTION`

### Pergunta 4 — Tipo de Aplicação
```
Será uma aplicação API ou Worker?
1. API — expõe endpoints síncronos
2. Worker — processa mensagens assíncronas
```
- Armazene como: `APP_TYPE` = `api` | `worker`

### Pergunta 4a — Sub-tipo API (somente se APP_TYPE = api)
```
Qual o protocolo da API?
1. REST (Spring Web MVC) — recomendado
2. gRPC
3. SOAP
```
- Armazene como: `API_PROTOCOL` = `rest` | `grpc` | `soap`
- Nota: o template tem suporte nativo a REST. gRPC e SOAP exigirão dependências extras (documente isso).

### Pergunta 4b — Sub-tipo Worker (somente se APP_TYPE = worker)
```
Qual o broker de mensageria?
1. Kafka (já incluído no template)
2. SQS (AWS)
```
- Armazene como: `WORKER_BROKER` = `kafka` | `sqs`

### Pergunta 5 — Banco de Dados
```
A aplicação terá banco de dados? Se sim, qual?
1. Não terá banco de dados
2. PostgreSQL (já incluído no template)
3. DynamoDB (já incluído no template)
4. Ambos (Postgres + DynamoDB)
```
- Armazene como: `DATABASE` = `none` | `postgres` | `dynamodb` | `both`

### Pergunta 6 — Cache
```
Terá camada de cache?
1. Não
2. Cache local (in-process, ex: Caffeine)
3. Cache via servidor (Valkey/Redis — já incluído no template)
```
- Armazene como: `CACHE` = `none` | `local` | `server`

### Pergunta 7 — Integrações HTTP
```
A aplicação terá integração com outras APIs (HTTP clients de saída)?
1. Não
2. Sim (OpenFeign — já incluído no template)
```
- Armazene como: `HTTP_CLIENT` = `none` | `feign`

---

## Fase 2 — Sumário e Confirmação

Antes de gerar qualquer arquivo, apresente um sumário ao usuário:

```
📋 Resumo do Projeto
─────────────────────────────────────────
📦 Namespace:     {NAMESPACE}
🏷️  Nome:          {PROJECT_NAME}
📝 Descrição:     {PROJECT_DESCRIPTION}
🔧 Tipo:          {APP_TYPE} ({API_PROTOCOL ou WORKER_BROKER})
🗄️  Banco de Dados: {DATABASE}
💾 Cache:         {CACHE}
🔌 HTTP Client:   {HTTP_CLIENT}

📁 Módulos que serão incluídos:
{lista baseada nas escolhas — ver Fase 3}

🔄 Tokens que serão substituídos:
  com.mycompany.template → {NAMESPACE}
  java-hexagonal-template → {PROJECT_NAME}
  hexagonal_db → {PROJECT_NAME_SNAKE}
  hexagonal-template-group → {PROJECT_NAME}-group

Confirmar a geração local do projeto? (sim/não)
```

Aguarde confirmação antes de prosseguir.

---

## Fase 3 — Decisão de Módulos

Com base nas respostas, determine quais módulos incluir:

| Condição | Módulos incluídos |
|---|---|
| Sempre | `core`, `application` |
| `APP_TYPE = api` | + `infra-api` |
| `APP_TYPE = worker` e broker = kafka | + `infra-kafka` |
| `APP_TYPE = worker` e broker = sqs | + `infra-kafka` (adaptar para SQS — ver nota abaixo) |
| `DATABASE = postgres` ou `both` | + `infra-postgres` |
| `DATABASE = dynamodb` ou `both` | + `infra-dynamodb` |
| `CACHE = server` | + `infra-valkey` |
| `HTTP_CLIENT = feign` | + `infra-client-api` |

**Nota SQS:** O template não tem módulo nativo para SQS. Use `infra-kafka` como base,
substitua as dependências do Spring Kafka pelo `spring-cloud-aws-starter-sqs`
e adapte o Listener para `@SqsListener`.

**Nota Cache Local:** Se `CACHE = local`, adicionar dependência `caffeine` no módulo
que precisar de cache (geralmente `infra-api` ou `application`). Não incluir `infra-valkey`.

---

## Fase 4 — Geração dos Arquivos Adaptados

Para cada arquivo do template, aplique as seguintes substituições de tokens:

```
com.mycompany.template  →  {NAMESPACE}
java-hexagonal-template →  {PROJECT_NAME}
JavaHexagonalTemplate   →  {PROJECT_CLASS_PREFIX}  (em nomes de classes)
hexagonal_db            →  {PROJECT_NAME_SNAKE}
hexagonal-template-group →  {PROJECT_NAME}-group
```

### Arquivos críticos a adaptar

Consulte `/references/files-to-adapt.md` para a lista completa com localização exata
de cada token por arquivo.

### Remoção de módulos não utilizados

Remova do `pom.xml` raiz as referências aos módulos excluídos:
```xml
<!-- Exemplo: se DATABASE != postgres, remover: -->
<module>infra-postgres</module>
```

E remova do `application/pom.xml` as dependências dos módulos excluídos.

---

## Fase 5 — Geração Local dos Arquivos

Execute na seguinte ordem:

1. **Criar a estrutura local do projeto** no workspace atual, preservando a organização do template.
2. **Para cada módulo incluído**, materializar os arquivos adaptados localmente.
   Priorize a ordem: `pom.xml` raiz → `core/` → módulos infra → `application/`.
3. **Criar arquivos adicionais:**
   - `README.md` adaptado (ver template em `/references/readme-template.md`)
   - `AGENT.md` atualizado com o contexto do novo projeto
   - `.gitignore` (copiar do original)
   - `docker-compose.yml` filtrado pelos serviços utilizados
4. **Executar a validação final do projeto**, nesta ordem:
   - `mvn clean compile`
   - `mvn test`
   - `mvn package`
5. **Confirmar ao usuário** que a geração foi concluída localmente e indicar os caminhos principais dos arquivos gerados.
6. **Se tudo tiver dado certo**, sugerir ao usuário criar um commit e fazer push para o repositório remoto, pedindo confirmação explícita antes de qualquer ação.

---

## Modo Offline (sem GitHub MCP)

Se o GitHub MCP não estiver disponível:
1. Use os arquivos de referência locais do pacote para continuar a geração no workspace.
2. Se algum dado do template remoto não puder ser lido, informe a limitação ao usuário.
3. Não faça commit nem push automáticos; a saída continua local.

---

## Referências

- `/references/files-to-adapt.md` — Lista exata de arquivos e tokens por arquivo
- `/references/readme-template.md` — Template de README.md para o novo projeto
- `/references/module-dependencies.md` — Dependências Maven por módulo para copiar

Leia esses arquivos conforme necessário durante a geração.
