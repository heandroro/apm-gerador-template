---
name: gerador-scaffold-java
description: "Use when the user wants to create a new Java project from the hexagonal template (https://github.com/heandroro/java-hexagonal-template). Triggers include: \"criar projeto\", \"novo projeto Java\", \"gerar projeto\", \"scaffolding\", \"criar repositório hexagonal\", \"novo serviço Java\", \"criar microserviço\", or any mention of starting a new Java service based on the hexagonal architecture template. Conducts a structured interview, reads template data via the GitHub MCP, and generates the adapted files locally in the workspace by default. Apply even when the user says only \"quero criar um projeto\" or \"me ajuda a criar um serviço novo\"."
argument-hint: "Opcionalmente informe o nome do projeto ou namespace (ex: payment-service, com.minhaempresa.pagamentos)"
---

# Agent Package Manager — Java Hexagonal Template

Este skill conduz uma entrevista estruturada com o usuário, coleta as decisões de projeto,
usa o GitHub MCP para ler os dados do template e gera os arquivos adaptados localmente
no workspace por padrão.

Referência oficial do APM: https://microsoft.github.io/apm/

---

## Diretriz de Eficiência de Contexto

Para otimizar custo de tokens e processamento da LLM:

1. Mantenha respostas curtas e orientadas a decisão; evite repetir blocos longos de instrução.
2. Carregue detalhes somente sob demanda a partir de `./references/*`.
3. No sumário de confirmação, apresente apenas variáveis finais, módulos selecionados e ações pendentes.
4. Evite reimprimir listas completas de tokens/arquivos quando não houver mudança.

---

## Pré-requisito: leitura do template via GitHub MCP

Antes de iniciar, verifique se as ferramentas do GitHub MCP estão disponíveis no contexto
(ex: `get_file_contents`).

Se não estiverem:
1. Informe o usuário que a leitura remota do template depende do GitHub MCP.
2. Indique o link: https://github.com/modelcontextprotocol/servers/tree/main/src/github
3. Interrompa o fluxo e aguarde o usuário conectar/configurar o GitHub MCP.

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
Qual o nome do projeto? (será usado como artifactId Maven)
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

### Perguntas 4+ — Dinâmicas por capacidade do template

Da Pergunta 4 em diante, gere perguntas dinamicamente com base nas capacidades do
template (não hardcode opções nesta etapa).

Fluxo obrigatório:
1. Ler capacidades do template via GitHub MCP (`get_file_contents`) a partir dos
   artefatos de manifesto/referência disponíveis.
2. Montar perguntas somente para capacidades existentes no template atual.
3. Exibir apenas opções válidas para cada capacidade.
4. Pular perguntas de capacidades não suportadas.
5. Se a leitura remota falhar, interromper o fluxo e pedir ao usuário para
   habilitar o GitHub MCP.

Mapeamento mínimo de saída (manter estas variáveis para as fases seguintes):
- `APP_TYPE` (quando o template suportar variação de tipo de aplicação)
- `API_PROTOCOL` (quando `APP_TYPE = api` e houver protocolos alternativos)
- `WORKER_BROKER` (quando `APP_TYPE = worker` e houver brokers alternativos)
- `DATABASE` (quando o template suportar opções de persistência)
- `CACHE` (quando o template suportar opções de cache)
- `HTTP_CLIENT` (quando o template suportar integrações HTTP de saída)

---

## Fase 2 — Sumário e Confirmação

Antes de gerar qualquer arquivo, apresente um sumário compacto:

- `NAMESPACE`, `PROJECT_NAME`, `PROJECT_DESCRIPTION`
- Tipo e capacidades selecionadas (`APP_TYPE`, protocolo/broker, `DATABASE`, `CACHE`, `HTTP_CLIENT`)
- Módulos finais que serão gerados (interseção entre escolhas e capacidades do template)
- Ação pendente: confirmação explícita do usuário para gerar localmente

Pergunta final obrigatória:

`Confirmar a geração local do projeto? (sim/não)`

Aguarde confirmação antes de prosseguir.

---

## Fase 3 — Decisão de Módulos

Decida os módulos com base no que o template realmente oferece.

Fluxo obrigatório:
1. Leia via GitHub MCP (`get_file_contents`) os artefatos de template/manifesto que
   indicam módulos e capacidades suportadas.
2. Monte a lista de módulos elegíveis do template atual.
3. Cruze as respostas do usuário com os módulos elegíveis e selecione apenas a interseção.
4. Trate capacidades pedidas pelo usuário que não existirem no template como divergência:
   - informe claramente a limitação,
   - proponha a alternativa mais próxima suportada,
   - aguarde confirmação antes de seguir.
5. Se a leitura remota falhar, interrompa o fluxo e peça ao usuário para
   habilitar o GitHub MCP.

Regras mínimas de seleção:
- Sempre incluir `core` e `application` quando estiverem disponíveis no template.
- Incluir módulos opcionais apenas se:
  - a capacidade foi solicitada pelo usuário, e
  - o módulo/capacidade existe no template atual.
- Não inventar módulo inexistente no template.

Adaptações condicionais (quando suportadas no template):
- SQS: usar o módulo de mensageria base indicado pelo template e aplicar adaptação SQS.
- Cache local: aplicar configuração local sem incluir módulo de cache servidor.

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

Consulte `./references/files-to-adapt.md` para a lista completa com localização exata
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
   - `README.md` adaptado (ver template em `./references/readme-template.md`)
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

## Referências

- `./references/files-to-adapt.md` — Lista exata de arquivos e tokens por arquivo
- `./references/readme-template.md` — Template de README.md para o novo projeto
- `./references/module-dependencies.md` — Dependências Maven por módulo para copiar

Leia esses arquivos conforme necessário durante a geração.
