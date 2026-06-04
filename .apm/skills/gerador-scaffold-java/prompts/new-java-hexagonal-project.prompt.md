---
name: new-java-hexagonal-project
description: "Generate a new Java Hexagonal Architecture project from the template. Use when the user wants to scaffold, create, or start a new Java microservice with hexagonal architecture."
---

Você quer criar um novo projeto Java com Arquitetura Hexagonal.

Vou conduzir uma entrevista rápida para coletar as configurações do projeto e então
gerar os arquivos localmente no workspace com base no template.

Por favor, responda às perguntas abaixo. Vou processar tudo ao final.

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

A partir da Pergunta 4, não use opções fixas hardcoded neste prompt.

Antes de continuar a entrevista:
1. Leia as capacidades do template via GitHub MCP (`get_file_contents`) a partir dos artefatos de template/manifesto disponíveis.
2. Gere somente as perguntas suportadas pelo template atual (ex.: tipo de app, protocolo/broker, banco, cache, integrações).
3. Para cada pergunta dinâmica, mostre apenas opções válidas naquele template.
4. Se uma capacidade não existir no template, não pergunte.
5. Se a leitura remota falhar, interrompa o fluxo e peça ao usuário para habilitar o GitHub MCP.

---

der certo, o skill deve apenas sugerir commit e push ao usuário, aguardando confirmação.
## Próximo passo

Após coletar as respostas:

1. Execute o skill `gerador-scaffold-java` com as variáveis preenchidas.
2. O skill deve gerar localmente no workspace.
3. Não faça commit nem push automáticos; apenas sugira ao usuário, com confirmação explícita.
