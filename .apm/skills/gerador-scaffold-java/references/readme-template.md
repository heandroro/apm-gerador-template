# README Template para Novo Projeto

Use este template para gerar o README.md do novo repositório.
Substitua todas as variáveis entre `{}`.

---

```markdown
# {PROJECT_NAME}

{PROJECT_DESCRIPTION}

## Stack

| Camada        | Tecnologia                                        |
| ------------- | ------------------------------------------------- |
| Linguagem     | Java 21                                           |
| Framework     | Spring Boot 3.5.0                                 |
{DB_ROW}
{CACHE_ROW}
{MESSAGING_ROW}
{HTTP_CLIENT_ROW}
| Mapeamento    | MapStruct 1.6                                     |

## Estrutura de Módulos

```
{PROJECT_NAME}/
├── core/                    # Regras de negócio — zero dependências de framework
{INFRA_API_ROW}
{INFRA_KAFKA_ROW}
{INFRA_POSTGRES_ROW}
{INFRA_DYNAMODB_ROW}
{INFRA_VALKEY_ROW}
{INFRA_CLIENT_ROW}
└── application/             # Spring Boot bootstrapper + configuração global
```

## Rodando Localmente

Pré-requisitos: Docker

```bash
# Subir infraestrutura
docker compose up -d

# Build & run
./mvnw clean package -pl application -am
java -jar application/target/application-1.0.0-SNAPSHOT.jar
```

## Namespace

Pacote base: `{NAMESPACE}`

## Arquitetura

Este projeto segue a **Arquitetura Hexagonal** com layout **Flat Multi-Módulo Maven**.
Consulte o [AGENT.md](./AGENT.md) para as regras arquiteturais completas.
```

---

## Variáveis de linha condicionais

**{DB_ROW}:**
- postgres: `| Persistência  | Spring Data JPA + PostgreSQL                      |`
- dynamodb: `| Persistência  | AWS DynamoDB (Spring Cloud AWS 3.3.0)             |`
- both:     ambas as linhas
- none:     omitir

**{CACHE_ROW}:**
- server: `| Cache         | Spring Data Redis (Valkey-compatible)             |`
- local:  `| Cache         | Caffeine (in-process)                             |`
- none:   omitir

**{MESSAGING_ROW}:**
- kafka: `| Mensageria    | Spring Kafka                                      |`
- sqs:   `| Mensageria    | AWS SQS (Spring Cloud AWS)                        |`
- none (api sem worker): omitir

**{HTTP_CLIENT_ROW}:**
- feign: `| HTTP Client   | Spring Cloud OpenFeign                            |`
- none:  omitir

**Linhas de módulos:**
- `├── infra-api/               # Adaptador REST de entrada (Spring Web MVC)`
- `├── infra-kafka/             # Adaptador de mensageria assíncrona (Kafka)`
- `├── infra-postgres/          # Adaptador de persistência relacional (JPA)`
- `├── infra-dynamodb/          # Adaptador de persistência NoSQL (DynamoDB)`
- `├── infra-valkey/            # Adaptador de cache (Valkey/Redis)`
- `├── infra-client-api/        # Adaptador HTTP de saída (OpenFeign)`
