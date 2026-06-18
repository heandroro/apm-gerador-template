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

**Nota sobre paths neste documento**: Todos os caminhos scripts (`scripts/fetch-template.sh`, etc.)
são **relativos à raiz da skill** (`.apm/skills/gerador-scaffold-java/`). Se a estrutura de 
diretórios mudar, manter os paths relativos será necessário (veja DEVELOPMENT.md para detalhes).

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

- **Fase 4.1 (Fetch dos arquivos-fonte)**: Um Bash para listar paths via git tree API, depois
  batches paralelos de `get_file_contents` via MCP (≤20 arquivos por batch). O mapa de tokens
  (Fase 4.2) pode ser preparado em paralelo com o primeiro batch de MCP.
- **Escritas de arquivo (Fase 4.3)**: após criar o `pom.xml` agregador raiz em `{workspace}/pom.xml`, emita TODOS os demais arquivos de módulos (`app/core/`, `app/application/`, `app/infra-*/`, etc.) em **uma única resposta** como Write tool calls paralelos.
- **Mapa de tokens (Fase 4.2)**: prepare-o em paralelo com os fetches da Fase 4.1 — depende apenas dos dados da Pré-Fase 1, sem dependência dos arquivos-fonte.

Regra geral: se múltiplas operações não têm dependência entre si, emita-as juntas em uma única resposta.

Para o relatório final (Fase 4.5), mantenha contadores internos durante a execução:
- `writes_total`: número de chamadas `Write` emitidas na Fase 4.3
- `writes_batches`: número de respostas em que essas escritas foram agrupadas

---

## Pré-requisito: Acesso ao Template (MCP → gh CLI → git)

**Este skill usa três métodos (em ordem de preferência):**

1. **MCP `get_file_contents`** (primário) — sem dependências externas; disponível sempre que
   o GitHub MCP estiver ativo na sessão Claude Code.

2. **gh CLI** (fallback) — até ~40 arquivos; requer instalação e autenticação.
   - Instalado? `which gh`
   - Autenticado? `gh auth status`
   - Se não: `brew install gh && gh auth login`

3. **git clone** (último recurso) — universal, ~30-50MB cache local.
   - Comando: `git --version` (já deve estar instalado)
   - Sem autenticação necessária para repositórios públicos

**Se nenhum estiver disponível**: Erro claro será exibido pedindo instalação.

### Segurança

Este fluxo é **somente leitura remota** do template público.

- ✅ Permitido: ler arquivos do template via MCP `get_file_contents`, gh CLI ou git clone
- ❌ Proibido: fazer push/commits ou modificar o template remoto
- ✅ Geração acontece apenas no workspace local do usuário

---

---

## Fluxo de Dados: Pré-Fase 1 → Fase 4

**Premissa importante**: Fase 4 **NÃO precisa de fetch adicional**, pois todos os dados necessários foram
carregados na Pré-Fase 1.

```
Pré-Fase 1: MCP get_file_contents (primário)
            ↳ fallback: gh CLI script (até ~40 arquivos)
            ↳ fallback: git clone (último recurso)
    ↓
    Obtém 3 arquivos:
    • TEMPLATE-MANIFEST.json → metadados de módulos e tokens
    • GENERATOR.json → perguntas para entrevista
    • README.md → template para novo README
    ↓
    Dados em contexto (+ cache local se obtidos via gh CLI ou git)

Fase 1-3: Entrevista & decisões (apenas manipulação de dados já em contexto)
    ↓
Fase 4: Geração local (reutiliza os 3 arquivos da Pré-Fase 1, **sem novas chamadas de fetch**)
    ↓
    Gera arquivos adaptados no workspace local
```

**Benefício**: MCP não requer ferramentas externas e está sempre disponível na sessão Claude Code.
**Fallback eficiente**: Se MCP falhar, gh CLI obtém até ~40 arquivos com ~5K tokens.

---

## Pré-Fase 1 — Orquestração de Fetch (MCP → gh CLI → git clone)

Tente os métodos abaixo em ordem. Ao primeiro sucesso, prossiga para Fase 1.

### Pré-verificação de cache (antes de qualquer método)

```bash
meta=".apm/skills/gerador-scaffold-java/cache/files/files.meta"
[ -f "$meta" ] && [ $(( $(date +%s) - $(cat "$meta") )) -lt 86400 ] && echo "HIT" || echo "MISS"
```

- **HIT** → carregar os 3 arquivos de `.apm/skills/gerador-scaffold-java/cache/files/` e ir direto para Fase 1.
- **MISS** → prosseguir para Método 1.

### Método 1 — MCP `get_file_contents` (primário)

Faça as **três chamadas em paralelo** (um único batch) usando o GitHub MCP
(owner/repo/branch definidos acima):

```
get_file_contents(owner, repo, "TEMPLATE-MANIFEST.json", branch)
get_file_contents(owner, repo, "GENERATOR.json",         branch)
get_file_contents(owner, repo, "README.md",              branch)
```

Se todos os 3 arquivos forem obtidos com sucesso:

1. Salve no cache em **um batch paralelo** (Write tool calls):
   - `TEMPLATE-MANIFEST.json` → `.apm/skills/gerador-scaffold-java/cache/files/TEMPLATE-MANIFEST.json`
   - `GENERATOR.json`         → `.apm/skills/gerador-scaffold-java/cache/files/GENERATOR.json`
   - `README.md`              → `.apm/skills/gerador-scaffold-java/cache/files/README.md`
2. Atualize o timestamp de validade:
   ```bash
   date +%s > .apm/skills/gerador-scaffold-java/cache/files/files.meta
   ```
3. Prosseguir para Fase 1.

Se o MCP falhar ou não estiver disponível: usar Método 2.

### Método 2 — gh CLI (fallback, até ~40 arquivos)

Execute o script otimizado com cache e retry:

```bash
.apm/skills/gerador-scaffold-java/scripts/fetch-template.sh heandroro java-hexagonal-template main 4 false
```

O script tenta gh CLI e, se falhar, cai automaticamente para git clone (Método 3).

### Método 3 — git clone (último recurso, acionado pelo script acima)

Invocado automaticamente por `fetch-template.sh` quando gh CLI falha:
```
.apm/skills/gerador-scaffold-java/scripts/fetch-template-git.sh
```

Se todos os métodos falharem: exibir erro claro ao usuário e interromper o skill.

### Contrato de Resposta — Métodos 2 e 3 (script)

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

| Status | Significado | Ação |
|--------|------------|------|
| **0** | ✅ Sucesso (todos 3 arquivos obtidos) | Extrair `.files{}` e prosseguir com Fase 1 |
| **1** | ❌ Falha total (gh CLI e git clone falharam) | Mostrar erro; interromper skill |

### Após receber os dados

Independentemente do método usado, você tem em contexto:
- `TEMPLATE-MANIFEST.json` — metadados de módulos
- `GENERATOR.json` — perguntas de entrevista
- `README.md` — template README

Estes dados **permanecem em contexto para todo o resto do skill** (Fases 1-4).
**Não refaça o fetch** — não repita chamadas MCP nem execute o script novamente.

---

## Fase 1 — Entrevista de Projeto

**Antes da primeira pergunta**, confirme que `TEMPLATE-MANIFEST.json` e `GENERATOR.json` estão
em contexto (carregados na Pré-Fase 1). **Não refaça o fetch** — os dados já estão disponíveis.

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

### 4.1 — Descobrir e buscar arquivos-fonte do template (git tree + MCP)

#### Passo 1 — Listar paths do template (um comando Bash)

Com base em `selectedModules[]` da Fase 3, construa o filtro `jq` dinamicamente e execute:

```bash
gh api 'repos/{TEMPLATE_OWNER}/{TEMPLATE_REPO}/git/trees/{TEMPLATE_BRANCH}?recursive=1' \
  --jq '[.tree[]
    | select(.type == "blob")
    | select(
        .path == "pom.xml"                                or
        .path == ".gitignore"                             or
        .path == "AGENTS.md"                              or
        (.path | startswith("app/core/"))                 or
        (.path | startswith("app/application/"))          or
        # repita um startswith para cada módulo infra em selectedModules[]:
        (.path | startswith("app/infra-postgres/"))       or
        (.path | startswith("infra/local/docker-compose"))
      )
    | .path
  ] | .[]'
```

> Substitua `{TEMPLATE_OWNER}`, `{TEMPLATE_REPO}`, `{TEMPLATE_BRANCH}` pelos valores do
> topo deste documento. Inclua um `startswith("app/{módulo}/")` por cada módulo em
> `selectedModules[]`. Exclua módulos não selecionados.

Resultado: lista de paths relativos à raiz do template (ex: `app/core/pom.xml`,
`app/core/src/main/java/com/mycompany/template/core/domain/User.java`).

#### Passo 2 — Buscar arquivos via MCP (batches paralelos, ≤20 por batch)

Para cada path da lista, chame `get_file_contents(owner, repo, path, branch)` em batches
paralelos de no máximo 20 chamadas por resposta.

Mantenha todos os conteúdos em contexto indexados pelo path do template.

> O mapa de tokens (Fase 4.2) **pode ser preparado em paralelo** com o primeiro batch —
> não há dependência entre eles.

Leia **somente os arquivos dos módulos selecionados** — ignore paths de módulos excluídos.

### 4.2 — Preparar mapa de substituição (em paralelo com Fase 4.1)

Monte o mapa de tokens **em paralelo com os batches de fetch da Fase 4.1** (sem dependência
entre eles). O mapa depende apenas dos dados da Pré-Fase 1 — não dos arquivos-fonte.

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
   Estrutura obrigatória:
   - `pom.xml` na raiz do workspace (agregador Maven — único `pom.xml` fora de `app/`)
   - Módulos em `app/{módulo}/` → `app/core/`, `app/application/`, `app/infra-*/`
   - Infraestrutura em `infra/local/docker-compose.yml`
   - Arquivos raiz: `README.md`, `AGENTS.md`, `.gitignore`
2. Para cada arquivo buscado na Fase 4.1, adaptar o conteúdo (não gerar — usar o conteúdo
   real do template):
   - Substituir todos os tokens conforme o mapa da Fase 4.2
   - Calcular o path de destino: path do template → substituir `com/mycompany/template/`
     por `{NAMESPACE_PATH}/` no caminho do arquivo
3. O path de destino final de cada arquivo é o path do template com a renomeação de pacote
   aplicada. Ex: `app/core/src/main/java/com/mycompany/template/core/domain/User.java`
   → `app/core/src/main/java/{NAMESPACE_PATH}/core/domain/User.java`.
4. Filtrar `infra/local/docker-compose.yml`: manter apenas os serviços presentes em `selectedDockerServices[]`.
5. Ordem de geração:
   - **Passo único**: criar `{workspace}/pom.xml` (pom agregador raiz — contém apenas as entradas
     `<module>app/{módulo}</module>` dos módulos selecionados; sem `<packaging>` ou código fonte).
   - **Em seguida**: emitir TODOS os demais arquivos (`app/core/`, módulos `app/infra-*/`,
     `app/application/`, `infra/local/docker-compose.yml`, `README.md`, `AGENTS.md`, `.gitignore`)
     em **uma única resposta** como Write tool calls paralelos — esses arquivos são independentes
     entre si.

Remover do `{workspace}/pom.xml` (pom raiz) as referências `<module>` de módulos excluídos.
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
