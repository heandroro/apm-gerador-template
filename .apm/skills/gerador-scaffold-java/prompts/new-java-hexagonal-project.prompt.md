---
name: new-java-hexagonal-project
description: "Generate a new Java Hexagonal Architecture project from the template. Use when the user wants to scaffold, create, or start a new Java microservice with hexagonal architecture."
---

Você quer criar um novo projeto Java com Arquitetura Hexagonal.

Vou conduzir uma entrevista rápida para coletar as configurações do projeto e então
gerar os arquivos localmente no workspace com base no template.

Por favor, responda às perguntas abaixo uma de cada vez.

---

## Configuração do Projeto

**1. Namespace (groupId Maven)**
> Ex: `com.minhaempresa.pagamentos`
>
> Namespace: {{namespace | default: "com.example"}}

---

**2. Nome do Projeto (artifactId Maven)**
> Ex: `payment-service`
>
> Nome: {{project_name | default: "my-service"}}

---

**3. Descrição do Projeto**
> Ex: `Serviço responsável por processar pagamentos via PIX e cartão.`
>
> Descrição: {{description | default: "Java microservice with hexagonal architecture"}}

---

**4+ Perguntas derivadas do template (dinâmicas)**

<!-- INSTRUÇÃO INTERNA PARA A LLM — não exibir ao usuário:
Antes de continuar a entrevista, leia `TEMPLATE-MANIFEST.json` do repositório de template
(owner: heandroro, repo: java-hexagonal-template, branch: main) via get_file_contents.

O manifesto expõe capacidades no formato:
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

Para cada chave em `capabilities` presente no manifesto:
- Gere uma pergunta ao usuário mostrando as opções válidas
- Pule a pergunta se a chave não existir no manifesto
- Nunca hardcode opções que não venham do manifesto

Se a leitura remota falhar, interrompa o fluxo e peça ao usuário para habilitar o GitHub MCP.
-->

---

## Próximo passo

Após coletar as respostas, execute o skill `gerador-scaffold-java` com as variáveis preenchidas.
O skill deve gerar localmente no workspace. Não faça commit nem push automáticos;
apenas sugira ao usuário, com confirmação explícita.
