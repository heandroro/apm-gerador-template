---
name: gerador-scaffold-java
description: "Use when the user wants to create a new Java project from the hexagonal template (https://github.com/heandroro/java-hexagonal-template). Triggers include: \"criar projeto\", \"novo projeto Java\", \"gerar projeto\", \"scaffolding\", \"criar repositório hexagonal\", \"novo serviço Java\", \"criar microserviço\", or any mention of starting a new Java service based on the hexagonal architecture template. Conducts a structured interview, reads template data via the GitHub MCP, and generates the adapted files locally in the workspace by default. Apply even when the user says only \"quero criar um projeto\" or \"me ajuda a criar um serviço novo\"."
argument-hint: "Opcionalmente informe o nome do projeto, namespace (ex: payment-service, com.minhaempresa.pagamentos), ou `--refresh-cache` para forçar releitura do template mesmo com cache válido."
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

Arquivos de entrada obrigatórios — leia **ambos** na Fase 1:
```
path: TEMPLATE-MANIFEST.json   → stack, módulos disponíveis, replaceTokens[], naming/mapper rules
path: GENERATOR.json           → profiles[] pré-configurados e questions[] para entrevista guiada
```

Leia cada um **uma única vez** na Fase 1 e reutilize o conteúdo em todas as fases seguintes.
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

- **Leituras MCP (Fase 4.1)**: emita TODAS as chamadas `get_file_contents` necessárias em **uma única resposta** como tool calls paralelos. Nunca leia arquivo por arquivo em mensagens separadas.
- **Escritas de arquivo (Fase 4.3)**: após criar o `pom.xml` raiz, emita TODOS os demais arquivos de módulos em **uma única resposta** como Write tool calls paralelos.
- **Mapa de tokens (Fase 4.2)**: prepare-o na **mesma resposta** em que emite as leituras MCP — o mapa depende apenas dos dados da Fase 1 e não precisa aguardar as leituras concluírem.

Regra geral: se múltiplas operações não têm dependência entre si, emita-as juntas em uma única resposta.

Para o relatório final (Fase 4.5), mantenha contadores internos durante a execução:
- `reads_total`: número de chamadas `get_file_contents` emitidas na Fase 4.1
- `reads_batches`: número de respostas em que essas chamadas foram agrupadas
- `writes_total`: número de chamadas `Write` emitidas na Fase 4.3
- `writes_batches`: número de respostas em que essas escritas foram agrupadas

---

## Pré-requisito: GitHub MCP com GITHUB_TOKEN

**Este skill REQUER GitHub MCP configurado com um `GITHUB_TOKEN` válido.**

### Verificação automática em tempo de execução

**Antes de iniciar**, execute este procedimento de detecção:

1. **Tente chamar `get_file_contents`** como teste:
   ```
   owner: heandroro
   repo: java-hexagonal-template
   path: TEMPLATE-MANIFEST.json
   ```

   **Resultado esperado:** sucesso → MCP está pronto, prossiga para Fase 1.

2. **Se a chamada falhar**, diagnostique o motivo:

   **Caso A: Erro de autenticação / token inválido**
   - **Mensagem ao usuário:**
     ```
     ❌ GitHub MCP retornou erro de autenticação.
     
     Solução:
     1. Verifique se GITHUB_TOKEN está configurado em settings.json
     2. Confirme que o token tem acesso ao repositório heandroro/java-hexagonal-template
     3. Tokens podem expirar — gere um novo em: https://github.com/settings/tokens
     
     Após atualizar, tente novamente.
     ```

   **Caso B: MCP não está ativo / ferramentas não disponíveis**
   - **Mensagem ao usuário:**
     ```
     ❌ GitHub MCP não está ativo ou acessível.
     
     Solução:
     1. Confirme que GitHub MCP está configurado em settings.json com GITHUB_TOKEN
     2. Restart Claude Code após configurar
     3. Consulte: https://github.com/modelcontextprotocol/servers/tree/main/src/github
     
     Após configurar e reiniciar, tente novamente.
     ```

   **Caso C: Outro erro (network, não consegue resolver hostname, etc)**
   - **Mensagem ao usuário:**
     ```
     ❌ Não consegui conectar ao GitHub para ler o template.
     
     Erro: [erro específico]
     
     Verificações:
     1. Conexão com internet está ativa?
     2. GitHub está acessível?
     3. Firewall/proxy está bloqueando?
     
     Tente novamente em alguns instantes.
     ```

### Regra de segurança obrigatória (GitHub MCP)

Este fluxo é **somente leitura remota**.

- ✅ Permitido: ler arquivos do template via `get_file_contents`.
- ❌ Proibido: qualquer escrita no repositório do template (`create`, `update`, `delete`, `push`, commits, PRs).
- ❌ Se ferramentas de escrita estiverem disponíveis, NÃO usar durante este skill.
- ✅ Geração acontece apenas no workspace local do usuário.

---

## Pré-Fase 1 — Verificação de Cache Local

Antes de fazer qualquer chamada MCP, verifique se existe um cache local válido.

**Localização do cache:** `.apm/skills/gerador-scaffold-java/cache/template-config.json`

**Estrutura esperada:**
```json
{
  "cachedAt": "2026-06-06T14:30:00Z",
  "templateVersion": "string",
  "manifest": { ...conteúdo de TEMPLATE-MANIFEST.json... },
  "generator": { ...conteúdo de GENERATOR.json... }
}
```

**Lógica de decisão:**

1. Verificar se o argumento `--refresh-cache` foi passado → se sim, pular para passo 3.
2. Tentar ler o arquivo de cache local:
   - Se existir e `cachedAt` for há menos de 24 horas → usar cache, pular chamadas MCP de configuração.
     Informar ao usuário: `[cache] Usando configuração do template em cache (atualizado em {cachedAt}).`
   - Se ausente ou `cachedAt` ≥ 24h atrás → prosseguir para passo 3.
3. Buscar via MCP (chamadas descritas na Fase 1 abaixo).
4. Após busca bem-sucedida, serializar o resultado em `.apm/skills/gerador-scaffold-java/cache/template-config.json`
   com `cachedAt` = timestamp ISO atual e `templateVersion` = valor de `TEMPLATE-MANIFEST.json.version`.
   Informar ao usuário: `[cache] Configuração do template atualizada.`

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

### 4.1 — Ler arquivos do template via MCP (paralelo)

Monte a lista completa de arquivos a ler para todos os módulos selecionados usando os caminhos
do `TEMPLATE-MANIFEST.json`. Em seguida, emita **todas as chamadas `get_file_contents` em uma
única resposta** como tool calls paralelos — não aguarde o resultado de uma leitura antes de
emitir a próxima.

Emita todas as chamadas `get_file_contents` dos módulos selecionados **simultaneamente**
— não sequencialmente. Aguarde todas concluírem antes de iniciar Phase 4.2.

Use os caminhos listados em `TEMPLATE-MANIFEST.json.modules[].manifest` para descobrir
os arquivos críticos de cada módulo.

Leia **somente os arquivos dos módulos selecionados** — não leia módulos excluídos.

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
   | Fase | Operações | Batches paralelos | Equivalente sequencial |
   |------|-----------|-------------------|------------------------|
   | 4.1 — Leitura MCP | `{reads_total}` arquivos | `{reads_batches}` batch(es) | `{reads_total}` chamadas |
   | 4.3 — Geração local | `{writes_total}` arquivos | `{writes_batches}` batch(es) | `{writes_total}` chamadas |

   Operações serializadas evitadas: `{(reads_total - reads_batches) + (writes_total - writes_batches)}`
   Para custo e tokens da sessão: verifique o comando de uso da sua harness (ex: `/cost` no Claude Code).

4. Sugira (mas não execute) criar um commit e fazer push, pedindo confirmação explícita.

---

## Referências

- `./references/files-to-adapt.md` — Regras estruturais de substituição por tipo de arquivo (Java, pom.xml, yaml, compose)
- `./references/readme-template.md` — Template de README.md para o novo projeto
- `./references/module-dependencies.md` — Regras de formato para entradas pom.xml e adaptações condicionais
