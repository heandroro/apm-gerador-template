---
name: new-java-hexagonal-project
description: "Generate a new Java Hexagonal Architecture project from the template. Use when the user wants to scaffold, create, or start a new Java microservice with hexagonal architecture."
---

You want to create a new Java project with Hexagonal Architecture.

I will conduct a quick interview to collect the project configuration and then
generate the files locally in the workspace based on the template.

Please answer the questions below one at a time.

---

## Project Configuration

**1. Namespace (Maven groupId)**
> Ex: `com.example.payments`
>
> Namespace: {{namespace | default: "com.example"}}

---

**2. Project Name (Maven artifactId)**
> Ex: `payment-service`
>
> Name: {{project_name | default: "my-service"}}

---

**3. Project Description**
> Ex: `Service responsible for processing payments via PIX and credit card.`
>
> Description: {{description | default: "Java microservice with hexagonal architecture"}}

---

**4+ Questions derived from the template (dynamic)**

<!-- INTERNAL INSTRUCTION FOR THE LLM — do not display to user:
Before continuing the interview, read `TEMPLATE-MANIFEST.json` from the template repository
(owner: heandroro, repo: java-hexagonal-template, branch: main) via get_file_contents.

The manifest exposes capabilities in the format:
{
  "modules": ["core", "application", "infra-api", "infra-kafka", ...],
  "capabilities": {
    "appTypes": ["api", "worker"],
    "protocols": ["rest", "grpc"],
    "brokers": ["kafka", "sqs"],
    "databases": ["postgres", "dynamodb"],
    "caches": ["server", "local", "none"],
    "httpClients": ["feign", "none"]
  }
}

For each key in `capabilities` present in the manifest:
- Generate a question to the user showing the valid options
- Skip the question if the key does not exist in the manifest
- Never hardcode options that do not come from the manifest

If the remote read fails, interrupt the flow and ask the user to enable GitHub MCP.
-->

---

## Next step

After collecting the answers, run the skill `java-scaffold-generator` with the filled variables.
The skill must generate locally in the workspace. Do not commit or push automatically;
only suggest it to the user, with explicit confirmation.
