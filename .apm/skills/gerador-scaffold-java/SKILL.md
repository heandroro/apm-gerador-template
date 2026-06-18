---
name: gerador-scaffold-java
description: "Use when the user wants to create a new Java project from the hexagonal template (https://github.com/heandroro/java-hexagonal-template). Triggers include: \"criar projeto\", \"novo projeto Java\", \"gerar projeto\", \"scaffolding\", \"criar repositório hexagonal\", \"novo serviço Java\", \"criar microserviço\", or any mention of starting a new Java service based on the hexagonal architecture template. Conducts a structured interview, reads template data via gh CLI (with git clone fallback), and generates the adapted files locally in the workspace by default. Apply even when the user says only \"quero criar um projeto\" or \"me ajuda a criar um serviço novo\"."
argument-hint: "Opcionalmente informe o nome do projeto, namespace (ex: payment-service, com.minhaempresa.pagamentos), ou `--refresh-cache` para forçar releitura do template mesmo com cache válido."
---

# Agent Package Manager — Java Hexagonal Template

Este skill conduz uma entrevista estruturada com o usuário, coleta as decisões de projeto,
usa o GitHub MCP para ler os dados do template e gera os arquivos adaptados localmente
no workspace por padrão.

Referência oficial do APM: https://microsoft.github.io/apm/

---

## Template de Referência (Configurável)

**Padrão**:
```
owner:  heandroro
repo:   java-hexagonal-template
branch: main
```

**Configurável via**:
- Variáveis de ambiente: `TEMPLATE_OWNER`, `TEMPLATE_REPO`, `TEMPLATE_BRANCH`
- CLI arguments: `.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh [owner] [repo] [branch]`

**Exemplo** (usar outro template):
```bash
TEMPLATE_OWNER=myorg TEMPLATE_REPO=my-template TEMPLATE_BRANCH=develop \
  .apm/skills/gerador-scaffold-java/scripts/fetch-template.sh
```

Valores são centralizados em `.apm/skills/gerador-scaffold-java/lib/template-config.sh`.

### Arquivos obrigatórios do template

```
path: TEMPLATE-MANIFEST.json   → stack, módulos disponíveis, replaceTokens[], naming/mapper rules
path: GENERATOR.json           → profiles[] pré-configurados e questions[] para entrevista guiada
path: README.md                → template para novo README
```

Leia cada um **uma única vez** na Pré-Fase 1 e reutilize o conteúdo em todas as fases seguintes.
O template é a **fonte da verdade**: módulos, tokens e perguntas vêm dos arquivos acima,
não de arquivos de referência locais deste gerador.
Não faça chamadas MCP adicionais sem necessidade explícita.

---

## Diretriz de Eficiência de Contexto

Para otimizar custo de tokens e processamento da LLM:

1. Leia `TEMPLATE-MANIFEST.json` e `GENERATOR.json` apenas uma vez (Fase 1) e mantenha em contexto.
2. Mantenha respostas curtas e orientadas a decisão; evite repetir blocos longos de instrução.
3. Carregue detalhes de `./references/*` somente quando a fase exigir (regras estruturais de formato).
4. No sumário de confirmação, apresente apenas variáveis finais, módulos selecionados e ações pendentes.
5. Evite reimprimir listas completas de tokens/arquivos quando não houver mudança.

---

## Diretriz de Paralelismo

Para minimizar o tempo total de execução, aplique batching de tool calls em operações de I/O:

- **Fase 4.1 (Leitura de template)**: Reutilize os dados já em contexto da Pré-Fase 1 — **não fazer tool calls**.
  Os arquivos foram carregados via gh CLI ou git clone, não precisam de chamadas MCP adicionais.
- **Escritas de arquivo (Fase 4.3)**: após criar o `pom.xml` raiz, emita TODOS os demais arquivos de módulos em **uma única resposta** como Write tool calls paralelos.
- **Mapa de tokens (Fase 4.2)**: prepare-o imediatamente — o mapa depende apenas dos dados da Fase 1 e não tem dependências externas.

Regra geral: se múltiplas operações não têm dependência entre si, emita-as juntas em uma única resposta.

Para o relatório final (Fase 4.5), mantenha contadores internos durante a execução:
- `writes_total`: número de chamadas `Write` emitidas na Fase 4.3
- `writes_batches`: número de respostas em que essas escritas foram agrupadas

---

## Pré-requisito: Acesso ao Template (gh CLI ou git)

**Este skill usa um dos dois métodos (em ordem de preferência):**

1. **gh CLI** (recomendado) — mais rápido, ~3-5s, ~5K tokens
   - Instalado? `which gh`
   - Autenticado? `gh auth status`
   - Se não: `brew install gh && gh auth login`

2. **git** (universal fallback) — sempre disponível, ~30-50MB cache local
   - Comando: `git --version` (já deve estar instalado)
   - Sem autenticação necessária para repositórios públicos

**Se nenhum estiver disponível**: Erro claro será exibido pedindo instalação.

### Segurança

Este fluxo é **somente leitura remota** do template público.

- ✅ Permitido: ler arquivos do template via gh CLI ou git clone
- ❌ Proibido: fazer push/commits, modificar template, usar MCP para escrita
- ✅ Geração acontece apenas no workspace local do usuário

---

---

## Fluxo de Dados: Pré-Fase 1 → Fase 4

**Premissa importante**: Fase 4 **NÃO precisa de MCP**, pois todos os dados necessários foram
carregados na Pré-Fase 1 via gh CLI ou git clone.

```
Pré-Fase 1: Fetch via gh CLI (ou git clone fallback)
    ↓
    Obtém 3 arquivos:
    • TEMPLATE-MANIFEST.json → metadados de módulos e tokens
    • GENERATOR.json → perguntas para entrevista
    • README.md → template para novo README
    ↓
    Cache local (.apm/skills/.../cache/files/)
    
Fase 1-3: Entrevista & decisões (apenas manipulação de dados já em contexto)
    ↓
Fase 4: Geração local (reutiliza os 3 arquivos da Pré-Fase 1, **sem chamadas MCP**)
    ↓
    Gera arquivos adaptados no workspace local
```

**Benefício**: Sem dependência de MCP em tempo de execução (Fase 4), apenas em Pré-Fase 1.
**Implicação**: Se gh CLI estiver disponível, todo o skill roda com ~5K tokens (vs ~150K com MCP).

---

## Pré-Fase 1 — Orquestração de Fetch (gh CLI com git clone Fallback)

O script shell otimizado tenta automaticamente, em ordem:

1. **gh CLI** (primário) — rápido, eficiente em tokens
2. **git clone** (fallback) — universal, sempre disponível

Script que orquestra isso:
```bash
.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh [owner] [repo] [branch] [batch_size] [refresh_cache]
```

### Execução automática

Quando o usuário diz algo como "criar projeto Java", o script é executado automaticamente:
```bash
.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh heandroro java-hexagonal-template main 4 false
```

### Contrato de Resposta (API Contract)

**JSON Response** (stdout):
```json
{
  "files": {
    "TEMPLATE-MANIFEST.json": "{ ...content... }",
    "GENERATOR.json": "{ ...content... }",
    "README.md": "# Template..."
  },
  "metadata": {
    "source": "gh-cli",        // or "git-clone-first" or "git-pull"
    "duration": "3s"
  },
  "status": 0
}
```

**Status Codes** (exit code + JSON `.status` field):

| Code | Significado | Ação |
|------|------------|------|
| **0** | ✅ Sucesso (todos 3 arquivos obtidos) | Extrair `.files{}` e prosseguir com Fase 1 |
| **1** | ❌ Falha total (gh CLI e git clone ambos falharam) | Mostrar erro ao usuário; interromper skill |

**Nota importante**: Ambos os scripts (fetch-template.sh e fetch-template-git.sh) retornam o **mesmo JSON**, apenas a origem (`metadata.source`) muda. Assim, o código LLM é transparente ao fallback.

### Após receber os dados

Independentemente da fonte (gh CLI ou git clone), você tem em contexto:
- `TEMPLATE-MANIFEST.json` — metadados de módulos
- `GENERATOR.json` — perguntas de entrevista
- `README.md` — template README

Estes dados **permanecem em contexto para todo o resto do skill** (Fases 1-4).
**Sem chamadas MCP adicionais necessárias.**

---

## Fase 1 — Entrevista de Projeto

**Antes da primeira pergunta**, leia os dois arquivos de configuração via `get_file_contents`
(owner/repo/branch definidos acima) — **somente se o cache não foi utilizado na Pré-Fase 1**.
Armazene ambos em contexto.

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

### Pergunta 4 — Perfil Pré-configurado

Antes de fazer perguntas individuais, leia `GENERATOR.json.profiles[]` (já em contexto)
e apresente os perfis disponíveis:

```
Existem perfis pré-configurados para casos de uso comuns:

• {profile.label}: {profile.description}
[listar todos os profiles[]]

Algum destes perfis se encaixa no que você precisa? (informe o nome ou "nenhum")
```

**Se o usuário escolher um perfil:**
- Ler `profiles[nome].modules[]`, `profiles[nome].dockerServices[]`, `profiles[nome].springProfiles[]`
- Registrar como `selectedModules[]`, `selectedDockerServices[]`, `selectedSpringProfiles[]`
- Pular as perguntas individuais (5+) — ir direto para Fase 2

**Se o usuário responder "nenhum" ou preferir personalizar:**
- Prosseguir com as Perguntas 5+ abaixo

### Perguntas 5+ — Individuais por capacidade (lidas de GENERATOR.json)

Se nenhum perfil foi escolhido, conduza as perguntas individualmente usando
`GENERATOR.json.questions[]` (já em contexto). **Não fazer nova chamada MCP.**

Para cada `question` em `questions[]`, em ordem:
1. Exibir `question.prompt` como texto da pergunta
2. Listar `option.label` para cada `option` em `question.options[]`
3. Se `question.multiSelect = true`, aceitar múltiplas respostas
4. Registrar a seleção pelo `question.id`

Ao final de todas as perguntas, consolidar:
- `selectedModules[]` = union de `option.modules[]` de todas as opções escolhidas
- `selectedDockerServices[]` = union de `option.dockerServices[]` de todas as opções escolhidas
- `selectedSpringProfiles[]` = union de `option.springProfiles[]` de todas as opções escolhidas

---

## Fase 2 — Sumário e Confirmação

Antes de gerar qualquer arquivo, apresente um sumário compacto:

- `NAMESPACE`, `PROJECT_NAME`, `PROJECT_DESCRIPTION`
- Perfil escolhido (se aplicável) ou respostas individuais por question.id
- Módulos que serão gerados: `selectedModules[]` (apenas os incluídos — não listar excluídos)
- Docker services a manter: `selectedDockerServices[]`
- Spring Profiles a ativar: `selectedSpringProfiles[]`
- Ação pendente: confirmação explícita do usuário para gerar localmente

Pergunta final obrigatória:

`Confirmar a geração local do projeto? (sim/não)`

Aguarde confirmação antes de prosseguir.

---

## Fase 3 — Decisão de Módulos

Decida os módulos com base nos dados já em contexto da Fase 1 — **não fazer nova chamada MCP**.

Fluxo obrigatório:
1. Partir de `selectedModules[]` coletados na Fase 1.
2. Adicionar sempre os módulos de `GENERATOR.json.postSetup.alwaysInclude` (ex: `core`, `application`).
3. Verificar exclusividade mútua usando `GENERATOR.json.postSetup.mutuallyExclusive`:
   - Se dois módulos mutuamente exclusivos estiverem na lista, informar o conflito,
     apresentar as opções em conflito e aguardar o usuário escolher uma.
4. Validar que todos os módulos selecionados existem em `TEMPLATE-MANIFEST.json.modules[]`.
   - Módulo inexistente → informar limitação, propor alternativa mais próxima, aguardar confirmação.

Consulte `./references/module-dependencies.md` apenas para as regras de **formato estrutural**
(como montar entradas `<module>` no pom.xml raiz e `<dependency>` no application/pom.xml).

---

## Fase 4 — Geração Local dos Arquivos Adaptados

Execute na seguinte ordem, sem pular etapas:

### 4.1 — Ler arquivos do template (já em cache local da Pré-Fase 1)

**IMPORTANTE**: Os arquivos do template **já foram carregados na Pré-Fase 1** via gh CLI ou git clone fallback.
**Não fazer chamadas MCP adicionais** — reutilizar os dados já em contexto.

#### Revisão dos dados em contexto (Pré-Fase 1)

Você já tem em contexto os 3 arquivos de configuração carregados na Pré-Fase 1:
- `TEMPLATE-MANIFEST.json` — lista completa de módulos e seus arquivos
- `GENERATOR.json` — perguntas de entrevista
- `README.md` — template README

Monte a lista de arquivos a gerar para todos os módulos selecionados usando os caminhos
do `TEMPLATE-MANIFEST.json.modules[].manifest[]`. 

Use os caminhos listados em `TEMPLATE-MANIFEST.json.modules[].manifest` para descobrir
os arquivos críticos de cada módulo.

Leia **somente os arquivos dos módulos selecionados** — não leia módulos excluídos.

**Próximo passo**: Fase 4.2 (mapa de tokens). Não há tool calls nesta subetapa — apenas análise de dados já em contexto.

### 4.2 — Preparar mapa de substituição (junto com 4.1)

Monte o mapa de tokens na **mesma resposta** em que emite as leituras MCP da Fase 4.1.
O mapa depende apenas dos dados coletados na Fase 1 — não há dependência das leituras de arquivo.

Monte o mapa de tokens usando `TEMPLATE-MANIFEST.json.replaceTokens[]` (já em contexto).

Para cada entrada em `replaceTokens[]`, associar o `token` original ao valor correspondente:

| `replaceTokens[].token` | Valor correspondente | Condição |
| --- | --- | --- |
| `com.mycompany.template` | `{NAMESPACE}` | Sempre |
| `com.mycompany` | `{NAMESPACE_ROOT}` | Sempre |
| `java-hexagonal-template` | `{PROJECT_NAME}` | Sempre |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | Sempre |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Sempre |
| `user-events-queue` | `{PROJECT_NAME_SNAKE}-events-queue` | Somente se `infra-sqs` selecionado |
| `user-events-topic` | `{PROJECT_NAME_SNAKE}-events-topic` | Somente se `infra-sns` selecionado |
| `users` | `{ENTITY_NAME_PLURAL}` | Somente se `infra-dynamodb` selecionado |

A lista acima reflete `replaceTokens[]` da versão atual do template. Se o template evoluir
e adicionar novos tokens, eles estarão em `replaceTokens[]` com suas `description` explicando
o contexto — adicione-os ao mapa antes de aplicar substituições.

Consulte `./references/files-to-adapt.md` para as regras de substituição por **tipo de arquivo**
(Java, pom.xml, application.yml, docker-compose.yml, etc.).

### 4.3 — Criar estrutura local e materializar arquivos (paralelo)

1. Criar a estrutura de diretórios no workspace preservando a organização do template.
2. Para cada arquivo de cada módulo incluído, aplicar as substituições do mapa acima.
3. Renomear caminhos de pacote Java: `com/mycompany/template/` → caminho derivado de `{NAMESPACE}`.
4. Filtrar `infra/local/docker-compose.yml`: manter apenas os serviços presentes em `selectedDockerServices[]`.
5. Ordem de geração:
   - **Passo único**: criar `pom.xml` raiz (inclui apenas `<module>` dos módulos selecionados).
   - **Em seguida**: emitir TODOS os demais arquivos (`core/`, módulos `infra-*`, `application/`,
     `README.md`, `AGENTS.md`, `.gitignore`) em **uma única resposta** como Write tool calls
     paralelos — esses arquivos são independentes entre si.

Remover do `pom.xml` raiz as referências `<module>` de módulos excluídos.
Remover do `app/application/pom.xml` as `<dependency>` de módulos excluídos.

### 4.4 — Validação Maven

Execute com um único comando (cobre compile → test → package em sequência interna):
```
mvn clean package
```

Se `mvn` não estiver no PATH, use `./mvnw clean package` (Maven Wrapper) quando o arquivo `mvnw` existir.

**Se o comando falhar:**
1. Exiba o erro completo ao usuário.
2. Identifique o arquivo e a linha responsável pelo erro.
3. Pergunte ao usuário se deve tentar corrigir automaticamente antes de continuar.
4. Só prossiga após confirmação explícita.

### 4.5 — Conclusão

1. Confirme ao usuário que a geração foi concluída localmente.
2. Liste os caminhos principais dos arquivos gerados.
3. Apresente o relatório de execução usando os contadores mantidos durante a execução:

   **Relatório de execução**
   | Fase | Operações | Batches paralelos | Nota |
   |------|-----------|-------------------|------|
   | Pré-Fase 1 — Fetch (gh CLI/git) | 3 arquivos | 1 | Executado automaticamente (fora desta skill) |
   | 4.3 — Geração local | `{writes_total}` arquivos | `{writes_batches}` batch(es) | Tool calls Write em paralelo |

   Operações serializadas evitadas: `{writes_total - writes_batches}`
   Para custo e tokens da sessão: verifique o comando de uso da sua harness (ex: `/cost` no Claude Code).

4. Sugira (mas não execute) criar um commit e fazer push, pedindo confirmação explícita.

---

## Referências

- `./references/files-to-adapt.md` — Regras estruturais de substituição por tipo de arquivo (Java, pom.xml, yaml, compose)
- `./references/readme-template.md` — Template de README.md para o novo projeto
- `./references/module-dependencies.md` — Regras de formato para entradas pom.xml e adaptações condicionais
