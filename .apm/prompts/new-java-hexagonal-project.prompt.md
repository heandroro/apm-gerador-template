---
name: new-java-hexagonal-project
description: "Generate a new Java Hexagonal Architecture project from the template. Use when the user wants to scaffold, create, or start a new Java microservice with hexagonal architecture."
---

Você quer criar um novo projeto Java com Arquitetura Hexagonal.

Vou conduzir uma entrevista rápida para coletar as configurações do projeto e então
criar o repositório GitHub com todos os arquivos adaptados automaticamente.

Por favor, responda às perguntas abaixo. Vou processar tudo ao final.

---

## Configuração do Projeto

**1. Namespace (groupId Maven)**
> Ex: `com.minhaempresa.pagamentos`
>
> Namespace: {{namespace | default: "com.example"}}

---

**2. Nome do Projeto (artifactId Maven / nome do repositório GitHub)**
> Ex: `payment-service`
>
> Nome: {{project_name | default: "my-service"}}

---

**3. Descrição do Projeto**
> Ex: `Serviço responsável por processar pagamentos via PIX e cartão.`
>
> Descrição: {{description | default: "Java microservice with hexagonal architecture"}}

---

**4. Tipo de Aplicação**
> Tipo: {{app_type | options: "api", "worker" | default: "api"}}

---

**5. Protocolo / Broker** _(depende do tipo)_
> Se `api`: protocolo da API
> Se `worker`: broker de mensageria
>
> Protocolo/Broker: {{protocol_or_broker | options: "rest", "grpc", "soap", "kafka", "sqs" | default: "rest"}}

---

**6. Banco de Dados**
> Banco: {{database | options: "none", "postgres", "dynamodb", "both" | default: "postgres"}}

---

**7. Cache**
> Cache: {{cache | options: "none", "local", "server" | default: "none"}}

---

**8. HTTP Client de saída**
> HTTP Client: {{http_client | options: "none", "feign" | default: "none"}}

---

**9. Visibilidade do repositório GitHub**
> Visibilidade: {{repo_visibility | options: "private", "public" | default: "private"}}

---

**10. Owner do repositório GitHub**
> Owner: {{github_owner | default: "heandroro"}}

---

## Instrução para o Agente

Com base nas respostas acima:

1. **Apresente um sumário** de todos os módulos que serão gerados e os tokens a substituir.
2. **Aguarde confirmação** do usuário antes de criar qualquer arquivo.
3. **Execute o skill `gerador-scaffold-java`** passando todas as variáveis coletadas.

O skill conduzirá a leitura do template via GitHub MCP, mas a geração final deve ocorrer
localmente no workspace. Não faça commit nem push automáticos neste fluxo; se tudo
der certo, o skill deve apenas sugerir commit e push ao usuário, aguardando confirmação.
