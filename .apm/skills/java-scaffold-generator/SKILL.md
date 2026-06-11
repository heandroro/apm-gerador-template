---
name: java-scaffold-generator
description: "Use when the user wants to create a new Java project from the hexagonal template (https://github.com/heandroro/java-hexagonal-template). Triggers include: \"create project\", \"new Java project\", \"generate project\", \"scaffolding\", \"create hexagonal repository\", \"new Java service\", \"create microservice\", or any mention of starting a new Java service based on the hexagonal architecture template. Conducts a structured interview, reads template data via the GitHub MCP, and generates the adapted files locally in the workspace by default. Apply even when the user says only \"I want to create a project\" or \"help me create a new service\"."
argument-hint: "Optionally provide the project name, namespace (e.g.: payment-service, com.example.payments), or `--refresh-cache` to force re-reading the template even with a valid cache."
---

# Agent Package Manager — Java Hexagonal Template

This skill conducts a structured interview with the user, collects project decisions,
uses the GitHub MCP to read template data, and generates the adapted files locally
in the workspace by default.

Official APM reference: https://microsoft.github.io/apm/

---

## Reference Template

```
owner:  heandroro
repo:   java-hexagonal-template
branch: main
```

Always use these values in `get_file_contents` calls. Never infer owner/repo from other sources.

Required input files — read **both** in Phase 1:
```
path: TEMPLATE-MANIFEST.json   → stack, available modules, replaceTokens[], naming/mapper rules
path: GENERATOR.json           → pre-configured profiles[] and questions[] for guided interview
```

Read each one **exactly once** in Phase 1 and reuse the content across all subsequent phases.
The template is the **source of truth**: modules, tokens, and questions come from the files above,
not from local reference files of this generator.
Do not make additional MCP calls without explicit need.

---

## Context Efficiency Directive

To optimize token cost and LLM processing:

1. Read `TEMPLATE-MANIFEST.json` and `GENERATOR.json` only once (Phase 1) and keep in context.
2. Keep responses short and decision-oriented; avoid repeating long instruction blocks.
3. Load details from `./references/*` only when the phase requires it (structural format rules).
4. In the confirmation summary, present only final variables, selected modules, and pending actions.
5. Avoid reprinting complete token/file lists when nothing has changed.

---

## Parallelism Directive

To minimize total execution time, apply tool call batching for I/O operations:

- **MCP reads (Phase 4.1)**: emit ALL required `get_file_contents` calls in **a single response** as parallel tool calls. Never read file by file in separate messages.
- **File writes (Phase 4.3)**: after creating the root `pom.xml`, emit ALL remaining module files in **a single response** as parallel Write tool calls.
- **Token map (Phase 4.2)**: prepare it in the **same response** where you emit the MCP reads — the map depends only on Phase 1 data and does not need to wait for the reads to complete.

General rule: if multiple operations have no dependency between them, emit them together in a single response.

For the final report (Phase 4.5), maintain internal counters during execution:
- `reads_total`: number of `get_file_contents` calls emitted in Phase 4.1
- `reads_batches`: number of responses in which those calls were batched
- `writes_total`: number of `Write` calls emitted in Phase 4.3
- `writes_batches`: number of responses in which those writes were batched

---

## Prerequisite: GitHub MCP with GITHUB_TOKEN

**This skill REQUIRES GitHub MCP configured with a valid `GITHUB_TOKEN`.**

### Automatic runtime check

**Before starting**, execute this detection procedure:

1. **Try calling `get_file_contents`** as a test:
   ```
   owner: heandroro
   repo: java-hexagonal-template
   path: TEMPLATE-MANIFEST.json
   ```

   **Expected result:** success → MCP is ready, proceed to Phase 1.

2. **If the call fails**, diagnose the reason:

   **Case A: Authentication error / invalid token**
   - **Message to user:**
     ```
     ❌ GitHub MCP returned an authentication error.
     
     Solution:
     1. Check that GITHUB_TOKEN is configured in settings.json
     2. Confirm the token has access to the heandroro/java-hexagonal-template repository
     3. Tokens can expire — generate a new one at: https://github.com/settings/tokens
     
     After updating, try again.
     ```

   **Case B: MCP is not active / tools not available**
   - **Message to user:**
     ```
     ❌ GitHub MCP is not active or accessible.
     
     Solution:
     1. Confirm that GitHub MCP is configured in settings.json with GITHUB_TOKEN
     2. Restart Claude Code after configuring
     3. See: https://github.com/modelcontextprotocol/servers/tree/main/src/github
     
     After configuring and restarting, try again.
     ```

   **Case C: Other error (network, unable to resolve hostname, etc.)**
   - **Message to user:**
     ```
     ❌ Could not connect to GitHub to read the template.
     
     Error: [specific error]
     
     Checks:
     1. Is your internet connection active?
     2. Is GitHub reachable?
     3. Is a firewall/proxy blocking the connection?
     
     Try again in a few moments.
     ```

### Mandatory security rule (GitHub MCP)

This flow is **remote read-only**.

- ✅ Allowed: read template files via `get_file_contents`.
- ❌ Forbidden: any write to the template repository (`create`, `update`, `delete`, `push`, commits, PRs).
- ❌ If write tools are available, do NOT use them during this skill.
- ✅ Generation happens only in the user's local workspace.

---

## Pre-Phase 1 — Local Cache Check

Before making any MCP call, check whether a valid local cache exists.

**Cache location:** `.apm/skills/java-scaffold-generator/cache/template-config.json`

**Expected structure:**
```json
{
  "cachedAt": "2026-06-06T14:30:00Z",
  "templateVersion": "string",
  "manifest": { ...contents of TEMPLATE-MANIFEST.json... },
  "generator": { ...contents of GENERATOR.json... }
}
```

**Decision logic:**

1. Check whether the `--refresh-cache` argument was passed → if so, skip to step 3.
2. Try to read the local cache file:
   - If it exists and `cachedAt` is less than 24 hours ago → use cache, skip MCP configuration calls.
     Inform the user: `[cache] Using cached template configuration (updated at {cachedAt}).`
   - If absent or `cachedAt` is ≥ 24h ago → proceed to step 3.
3. Fetch via MCP (calls described in Phase 1 below).
4. After a successful fetch, serialize the result to `.apm/skills/java-scaffold-generator/cache/template-config.json`
   with `cachedAt` = current ISO timestamp and `templateVersion` = value from `TEMPLATE-MANIFEST.json.version`.
   Inform the user: `[cache] Template configuration updated.`

---

## Phase 1 — Project Interview

**Before the first question**, read the two configuration files via `get_file_contents`
(owner/repo/branch defined above) — **only if the cache was not used in Pre-Phase 1**.
Store both in context.

Ask the questions below **one at a time**, waiting for the answer before proceeding.
Use friendly language and concrete examples to guide the user.

### Question 1 — Namespace
```
What will the namespace (Maven groupId) of the project be?
Example: com.example.payments
```
- Validate that it is a valid Java package (lowercase, no hyphens, no spaces).
- Store as: `NAMESPACE`
- Derive: `NAMESPACE_ROOT` = leading segments of the namespace excluding the last one
  (e.g.: `com.example.payments` → `NAMESPACE_ROOT = com.example`).
  If the namespace has only 2 segments, `NAMESPACE_ROOT = NAMESPACE`.

### Question 2 — Project Name
```
What is the project name? (will be used as the Maven artifactId)
Example: payment-service
```
- Validate: lowercase, hyphens allowed, no spaces.
- Store as: `PROJECT_NAME`
- Derive: `PROJECT_NAME_SNAKE` = PROJECT_NAME with hyphens → underscores (for DB name).

### Question 3 — Description
```
What is the project description? (will be used in README.md and pom.xml)
Example: Service responsible for processing payments via PIX and credit card.
```
- Store as: `PROJECT_DESCRIPTION`

### Question 4 — Pre-configured Profile

Before asking individual questions, read `GENERATOR.json.profiles[]` (already in context)
and present the available profiles:

```
There are pre-configured profiles for common use cases:

• {profile.label}: {profile.description}
[list all profiles[]]

Does any of these profiles fit what you need? (provide the name or "none")
```

**If the user chooses a profile:**
- Read `profiles[name].modules[]`, `profiles[name].dockerServices[]`, `profiles[name].springProfiles[]`
- Register as `selectedModules[]`, `selectedDockerServices[]`, `selectedSpringProfiles[]`
- Skip individual questions (5+) — go directly to Phase 2

**If the user answers "none" or prefers to customize:**
- Proceed with Questions 5+ below

### Questions 5+ — Individual per capability (read from GENERATOR.json)

If no profile was chosen, conduct the questions individually using
`GENERATOR.json.questions[]` (already in context). **Do not make a new MCP call.**

For each `question` in `questions[]`, in order:
1. Display `question.prompt` as the question text
2. List `option.label` for each `option` in `question.options[]`
3. If `question.multiSelect = true`, accept multiple answers
4. Record the selection by `question.id`

At the end of all questions, consolidate:
- `selectedModules[]` = union of `option.modules[]` from all chosen options
- `selectedDockerServices[]` = union of `option.dockerServices[]` from all chosen options
- `selectedSpringProfiles[]` = union of `option.springProfiles[]` from all chosen options

---

## Phase 2 — Summary and Confirmation

Before generating any file, present a compact summary:

- `NAMESPACE`, `PROJECT_NAME`, `PROJECT_DESCRIPTION`
- Chosen profile (if applicable) or individual answers by question.id
- Modules to be generated: `selectedModules[]` (only the included ones — do not list excluded)
- Docker services to keep: `selectedDockerServices[]`
- Spring Profiles to activate: `selectedSpringProfiles[]`
- Pending action: explicit user confirmation to generate locally

Mandatory final question:

`Confirm local project generation? (yes/no)`

Wait for confirmation before proceeding.

---

## Phase 3 — Module Decision

Decide the modules based on data already in context from Phase 1 — **do not make a new MCP call**.

Required flow:
1. Start from `selectedModules[]` collected in Phase 1.
2. Always add the modules from `GENERATOR.json.postSetup.alwaysInclude` (e.g.: `core`, `application`).
3. Check mutual exclusivity using `GENERATOR.json.postSetup.mutuallyExclusive`:
   - If two mutually exclusive modules are in the list, report the conflict,
     present the conflicting options, and wait for the user to choose one.
4. Validate that all selected modules exist in `TEMPLATE-MANIFEST.json.modules[]`.
   - Non-existent module → report the limitation, propose the closest alternative, wait for confirmation.

Consult `./references/module-dependencies.md` only for the **structural format** rules
(how to assemble `<module>` entries in the root pom.xml and `<dependency>` in application/pom.xml).

---

## Phase 4 — Local Generation of Adapted Files

Execute in the following order, without skipping steps:

### 4.1 — Read template files via MCP (parallel)

Assemble the complete list of files to read for all selected modules using the paths
from `TEMPLATE-MANIFEST.json`. Then emit **all `get_file_contents` calls in a single
response** as parallel tool calls — do not wait for the result of one read before
emitting the next.

Emit all `get_file_contents` calls for selected modules **simultaneously**
— not sequentially. Wait for all of them to complete before starting Phase 4.2.

Use the paths listed in `TEMPLATE-MANIFEST.json.modules[].manifest` to discover
the critical files for each module.

Read **only the files from selected modules** — do not read excluded modules.

### 4.2 — Prepare substitution map (together with 4.1)

Assemble the token map in the **same response** where you emit the MCP reads from Phase 4.1.
The map depends only on data collected in Phase 1 — there is no dependency on the file reads.

Assemble the token map using `TEMPLATE-MANIFEST.json.replaceTokens[]` (already in context).

For each entry in `replaceTokens[]`, associate the original `token` with the corresponding value:

| `replaceTokens[].token` | Corresponding value | Condition |
| --- | --- | --- |
| `com.mycompany.template` | `{NAMESPACE}` | Always |
| `com.mycompany` | `{NAMESPACE_ROOT}` | Always |
| `java-hexagonal-template` | `{PROJECT_NAME}` | Always |
| `hexagonal_db` | `{PROJECT_NAME_SNAKE}` | Always |
| `hexagonal-template-group` | `{PROJECT_NAME}-group` | Always |
| `user-events-queue` | `{PROJECT_NAME_SNAKE}-events-queue` | Only if `infra-sqs` selected |
| `user-events-topic` | `{PROJECT_NAME_SNAKE}-events-topic` | Only if `infra-sns` selected |
| `users` | `{ENTITY_NAME_PLURAL}` | Only if `infra-dynamodb` selected |

The table above reflects `replaceTokens[]` from the current version of the template. If the template
evolves and adds new tokens, they will be in `replaceTokens[]` with their `description` explaining
the context — add them to the map before applying substitutions.

Consult `./references/files-to-adapt.md` for the substitution rules per **file type**
(Java, pom.xml, application.yml, docker-compose.yml, etc.).

### 4.3 — Create local structure and materialize files (parallel)

1. Create the directory structure in the workspace preserving the template organization.
2. For each file of each included module, apply the substitutions from the map above.
3. Rename Java package paths: `com/mycompany/template/` → path derived from `{NAMESPACE}`.
4. Filter `infra/local/docker-compose.yml`: keep only the services present in `selectedDockerServices[]`.
5. Generation order:
   - **Single step**: create root `pom.xml` (includes only `<module>` for selected modules).
   - **Then**: emit ALL remaining files (`core/`, `infra-*` modules, `application/`,
     `README.md`, `AGENTS.md`, `.gitignore`) in **a single response** as parallel Write tool calls
     — these files are independent of each other.

Remove `<module>` references for excluded modules from the root `pom.xml`.
Remove `<dependency>` entries for excluded modules from `app/application/pom.xml`.

### 4.4 — Maven Validation

Execute with a single command (covers compile → test → package internally):
```
mvn clean package
```

If `mvn` is not in PATH, use `./mvnw clean package` (Maven Wrapper) when the `mvnw` file exists.

**If the command fails:**
1. Display the full error to the user.
2. Identify the file and line responsible for the error.
3. Ask the user whether to attempt an automatic fix before continuing.
4. Only proceed after explicit confirmation.

### 4.5 — Completion

1. Confirm to the user that generation was completed locally.
2. List the main paths of the generated files.
3. Present the execution report using the counters maintained during execution:

   **Execution report**
   | Phase | Operations | Parallel batches | Sequential equivalent |
   |-------|-----------|------------------|-----------------------|
   | 4.1 — MCP reads | `{reads_total}` files | `{reads_batches}` batch(es) | `{reads_total}` calls |
   | 4.3 — Local generation | `{writes_total}` files | `{writes_batches}` batch(es) | `{writes_total}` calls |

   Serialized operations avoided: `{(reads_total - reads_batches) + (writes_total - writes_batches)}`
   For session cost and tokens: check your harness usage command (e.g.: `/cost` in Claude Code).

4. Suggest (but do not execute) creating a commit and pushing, asking for explicit confirmation.

---

## References

- `./references/files-to-adapt.md` — Structural substitution rules by file type (Java, pom.xml, yaml, compose)
- `./references/readme-template.md` — README.md template for the new project
- `./references/module-dependencies.md` — Format rules for pom.xml entries and conditional adaptations
