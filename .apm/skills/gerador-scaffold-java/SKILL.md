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

## Template de Referência

```
owner:  heandroro
repo:   java-hexagonal-template
branch: main
```

Use sempre estes valores nas chamadas `get_file_contents`. Nunca infira owner/repo de outras fontes.

Ponto de entrada obrigatório:
```
path: TEMPLATE-MANIFEST.json
```

Este arquivo lista todos os módulos disponíveis e as capacidades suportadas pelo template.
Leia-o **uma única vez** na Fase 1 e reutilize seu conteúdo em todas as fases seguintes.
Não faça chamadas MCP adicionais sem necessidade explícita.

---

## Diretriz de Eficiência de Contexto

Para otimizar custo de tokens e processamento da LLM:

1. Leia `TEMPLATE-MANIFEST.json` apenas uma vez (Fase 1) e mantenha em contexto.
2. Mantenha respostas curtas e orientadas a decisão; evite repetir blocos longos de instrução.
3. Carregue detalhes de `./references/*` somente quando a fase exigir.
4. No sumário de confirmação, apresente apenas variáveis finais, módulos selecionados e ações pendentes.
5. Evite reimprimir listas completas de tokens/arquivos quando não houver mudança.

---

## Pré-requisito: leitura do template via GitHub MCP

Antes de iniciar, verifique se as ferramentas do GitHub MCP estão disponíveis no contexto
(ex: `get_file_contents`).


### Regra de segurança obrigatória (GitHub MCP)

Este fluxo é **somente leitura remota**.

- Permitido: ler arquivos do template (`get_file_contents`, busca textual/leitura equivalente).
- Proibido: qualquer escrita remota no repositório do template (`create`, `update`, `delete`, `push`, PR, branch, commit remoto).
- Se alguma ferramenta de escrita estiver disponível no contexto, **não usar** durante este skill.
- A geração deve acontecer apenas no workspace local do usuário.
- Se faltar informação do template, buscar alternativas de leitura (ex.: listagem local temporária) sem alterar o remoto.

Se não estiverem:
1. Informe o usuário que a leitura remota do template depende do GitHub MCP.
2. Indique o link: https://github.com/modelcontextprotocol/servers/tree/main/src/github
3. Interrompa o fluxo e aguarde o usuário conectar/configurar o GitHub MCP.

---

## Fase 1 — Entrevista de Projeto

**Antes da primeira pergunta**, leia `TEMPLATE-MANIFEST.json` via `get_file_contents`
(owner/repo/branch definidos acima). Armazene o resultado em contexto.

Faça as perguntas abaixo **uma de cada vez**, aguardando a resposta antes de prosseguir.
Use linguagem amigável e exemplos concretos para guiar o usuário.

### Pergunta 1 — Namespace
```
Qual será o namespace (groupId Maven) do projeto?
Exemplo: com.minhaempresa.pagamentos
```
- Valide que seja um pacote Java válido (lowercase, sem hífens, sem espaços).
- Armazene como: `NAMESPACE`
- Derive: `NAMESPACE_ROOT` = segmentos iniciais do namespace excluindo o último
  (ex: `com.minhaempresa.pagamentos` → `NAMESPACE_ROOT = com.minhaempresa`).
  Se o namespace tiver apenas 2 segmentos, `NAMESPACE_ROOT = NAMESPACE`.

### Pergunta 2 — Nome do Projeto
```
Qual o nome do projeto? (será usado como artifactId Maven)
Exemplo: payment-service
```
- Valide: lowercase, hífens permitidos, sem espaços.
- Armazene como: `PROJECT_NAME`
- Derive: `PROJECT_NAME_SNAKE` = PROJECT_NAME com hífens → underscores (para DB name).

### Pergunta 3 — Descrição
```
Qual a descrição do projeto? (será usada no README.md e no pom.xml)
Exemplo: Serviço responsável por processar pagamentos via PIX e cartão.
```
- Armazene como: `PROJECT_DESCRIPTION`

### Perguntas 4+ — Dinâmicas por capacidade do template

Da Pergunta 4 em diante, gere perguntas dinamicamente com base nas capacidades lidas
do `TEMPLATE-MANIFEST.json` (já em contexto desde o início da Fase 1).

Fluxo obrigatório:
1. Usar o `TEMPLATE-MANIFEST.json` já carregado — **não fazer nova chamada MCP**.
2. Montar perguntas somente para capacidades presentes no manifesto.
3. Exibir apenas opções válidas para cada capacidade.
4. Pular perguntas de capacidades não suportadas.

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

Decida os módulos com base no `TEMPLATE-MANIFEST.json` já em contexto.

Fluxo obrigatório:
1. Usar o manifesto já carregado na Fase 1 — **não fazer nova chamada MCP**.
2. Monte a lista de módulos elegíveis do template atual.
3. Cruze as respostas do usuário com os módulos elegíveis e selecione apenas a interseção.
4. Trate capacidades pedidas pelo usuário que não existirem no template como divergência:
   - informe claramente a limitação,
   - proponha a alternativa mais próxima suportada,
   - aguarde confirmação antes de seguir.

Regras mínimas de seleção:
- Sempre incluir `core` e `application` quando estiverem disponíveis no template.
- Incluir módulos opcionais apenas se:
  - a capacidade foi solicitada pelo usuário, e
  - o módulo/capacidade existe no template atual.
- Não inventar módulo inexistente no template.

Adaptações condicionais (quando suportadas no template):
- SQS: usar o módulo de mensageria base indicado pelo template e aplicar adaptação SQS.
- Cache local: aplicar configuração local sem incluir módulo de cache servidor.

Consulte `./references/module-dependencies.md` para as regras detalhadas de seleção
e dependências inter-módulo.

---

## Fase 4 — Geração Local dos Arquivos Adaptados

Execute na seguinte ordem, sem pular etapas:

### 4.1 — Ler arquivos do template via MCP

Para cada módulo selecionado, leia os arquivos necessários via `get_file_contents`.
Use os caminhos listados no `TEMPLATE-MANIFEST.json`.
Leia **somente os arquivos dos módulos selecionados** — não leia módulos excluídos.

### 4.2 — Preparar mapa de substituição

Monte o mapa de tokens com os valores coletados na Fase 1:

```
com.mycompany.template   →  {NAMESPACE}
com.mycompany            →  {NAMESPACE_ROOT}
java-hexagonal-template  →  {PROJECT_NAME}   (artifactId, spring.application.name e referências no código)
hexagonal_db             →  {PROJECT_NAME_SNAKE}
hexagonal-template-group →  {PROJECT_NAME}-group
```

Consulte `./references/files-to-adapt.md` para as regras de substituição por tipo de arquivo.

### 4.3 — Criar estrutura local e materializar arquivos

1. Criar a estrutura de diretórios no workspace preservando a organização do template.
2. Para cada arquivo de cada módulo incluído, aplicar as substituições do mapa acima.
3. Renomear caminhos de pacote: `com/mycompany/template/` → caminho derivado de `{NAMESPACE}`.
4. Ordem de geração: `pom.xml` raiz → `core/` → módulos `infra-*` → `application/`.

Arquivos adicionais a criar:
- `README.md` adaptado (use `./references/readme-template.md`)
- `AGENT.md` com contexto do novo projeto
- `.gitignore` (copiar do template)
- `docker-compose.yml` filtrado pelos serviços utilizados

Remover do `pom.xml` raiz as referências `<module>` de módulos excluídos.
Remover do `application/pom.xml` as `<dependency>` de módulos excluídos.

### 4.4 — Validação Maven

Execute em sequência:
```
mvn clean compile
mvn test
mvn package
```

**Se qualquer comando falhar:**
1. Exiba o erro completo ao usuário.
2. Identifique o arquivo e a linha responsável pelo erro.
3. Pergunte ao usuário se deve tentar corrigir automaticamente antes de continuar.
4. Só prossiga após confirmação explícita.

### 4.5 — Conclusão

1. Confirme ao usuário que a geração foi concluída localmente.
2. Liste os caminhos principais dos arquivos gerados.
3. Sugira (mas não execute) criar um commit e fazer push, pedindo confirmação explícita.

---

## Referências

- `./references/files-to-adapt.md` — Regras de substituição de tokens por tipo de arquivo
- `./references/readme-template.md` — Template de README.md para o novo projeto
- `./references/module-dependencies.md` — Dependências Maven por módulo e regras de seleção
