# Descrição da Arquitetura — Atividade 04

**Projeto:** Modelagem Arquitetural e Boas Práticas de Engenharia de Software Aplicadas ao Desenvolvimento de Sistemas Escaláveis  
**Autor:** Gabriel Ribeiro de Camargo Miranda  
**Data:** Maio/2026  
**Versão:** 1.0

---

## 1. Visão Geral da Arquitetura

A solução proposta implementa uma arquitetura **cloud-native e escalável** baseada em padrões modernos de engenharia de software, utilizando a plataforma **Amazon Web Services (AWS)** como infraestrutura. A arquitetura foi projetada para suportar crescimento sob demanda, manutenção evolutiva e observabilidade completa de componentes distribuídos.

---

## 2. Componentes Principais

### 2.1. Camada de Apresentação (Front-end)

**Tecnologia:** SPA (Single Page Application) com React ou Next.js

**Hospedagem:** AWS S3 + CloudFront

**Características:**
- Aplicação web responsiva com renderização client-side ou server-side
- Distribuição de conteúdo estático via CDN (CloudFront)
- Cache de longa duração em edge locations
- Redução de latência global através de replicação geográfica

**Benefícios:**
- Escalabilidade automática (sem gerenciamento de servidores)
- Redução de custos com suporte nativo a HTTPS e HTTP/2
- Experiência de usuário otimizada com acesso de baixa latência mundial

---

### 2.2. Camada de API e Roteamento

**Tecnologia:** AWS API Gateway

**Características:**
- Gerenciamento centralizado de endpoints RESTful
- Throttling e rate limiting automáticos
- Autenticação e autorização (integração com AWS Cognito)
- Versionamento de API com suportes a múltiplas stages

**Benefícios:**
- Isolamento entre clientes e backend
- Proteção contra ataques DDoS
- Logs estruturados e métricas nativas

---

### 2.3. Camada de Negócio (Back-end)

#### 2.3.1. Abordagem 1 — Serverless (AWS Lambda)

**Arquitetura:** Microsserviços event-driven

**Componentes:**
- AWS Lambda para funções computacionais
- AWS SQS / SNS para comunicação assíncrona
- AWS Step Functions para orquestração de workflows

**Características:**
- Execução de código sob demanda sem gerenciamento de infraestrutura
- Escalabilidade automática com billing por execução
- Integrações nativas com outros serviços AWS

**Casos de Uso:**
- Processamento de requisições síncronas (APIs)
- Processamento batch assíncrono
- Gatilhos automáticos baseados em eventos

#### 2.3.2. Abordagem 2 — Microsserviços em Containers (AWS ECS/Fargate)

**Arquitetura:** Containers Docker orquestrados

**Componentes:**
- AWS ECS (Elastic Container Service)
- AWS Fargate para gerenciamento serverless
- AWS ECR (Elastic Container Registry)

**Características:**
- Portabilidade entre ambientes (local, staging, produção)
- Versionamento de imagens e rollback automático
- Service discovery e load balancing nativo

**Casos de Uso:**
- Serviços com estado duradouro
- Processamento de longa duração
- Compatibilidade com Docker Compose local

---

### 2.4. Camada de Persistência

#### 2.4.1. Amazon RDS (PostgreSQL)

**Função:** Banco de dados relacional

**Características:**
- Managed database service com backup automático
- Replicação para alta disponibilidade
- Suporte a read replicas para escalabilidade de leitura
- Criptografia em repouso e em trânsito

**Dados Armazenados:**
- Entidades relacionais (usuários, projetos, tarefas)
- Histórico transacional
- Metadados operacionais

#### 2.4.2. Amazon DynamoDB

**Função:** Banco de dados NoSQL para alta performance

**Características:**
- Pré-alocação de capacidade ou modo sob demanda
- Replicação global (multi-region)
- Índices secundários GSI (Global Secondary Index)

**Dados Armazenados:**
- Cache distribuído de sessões
- Dados de alta velocidade (rankings, logs de acesso)
- Dados semi-estruturados (JSON)

---

### 2.5. Autenticação e Autorização

**Tecnologia Principal:** AWS Cognito ou JWT Customizado

#### 2.5.1. AWS Cognito

**Características:**
- Gerenciamento nativo de usuários
- Suporte a MFA (Multi-Factor Authentication)
- Integração social (Google, Facebook, GitHub)
- Compliance com standards (OIDC, SAML)

#### 2.5.2. JWT Customizado

**Características:**
- Tokens assinados com RS256
- Emissão por lambda authorizer
- Validação stateless em cada requisição

**Benefício:** Flexibilidade para regras customizadas de negócio

---

### 2.6. Observabilidade e Monitoramento

**Tecnologia Principal:** AWS CloudWatch

**Componentes:**
- **CloudWatch Logs:** Agregação centralizada de logs estruturados
- **CloudWatch Metrics:** Coleta e visualização de métricas customizadas
- **CloudWatch Alarms:** Alertas automáticos com integração SNS
- **X-Ray:** Distributed tracing para análise de latência entre serviços

**Dashboards:**
- Taxa de erro por serviço
- Tempo de resposta (P50, P95, P99)
- Uso de recursos (CPU, memória, I/O)
- Custo por serviço

**Benefícios:**
- Identificação rápida de anomalias
- Root cause analysis de falhas distribuídas
- Otimização contínua de performance

---

## 3. Fluxo de Dados

```
Usuário (Navegador)
         ↓
    CloudFront
         ↓
    S3 (SPA React/Next.js)
         ↓
   API Gateway
         ↓
AWS Lambda / ECS Fargate
         ↓
   RDS (PostgreSQL)
   DynamoDB
         ↓
   CloudWatch (Observabilidade)
```

---

## 4. Características Arquiteturais

### 4.1. Escalabilidade

- **Horizontal:** Múltiplas instâncias de Lambda/Fargate com load balancing automático
- **Vertical:** Upgrade de recursos de RDS mediante demanda
- **Temporal:** Auto-scaling baseado em métricas (CPU, requisições/s)

### 4.2. Resiliência

- **Redundância:** Replicação em múltiplas availability zones (AZs)
- **Circuit Breaker:** Padrão implementado entre serviços
- **Retry Logic:** Backoff exponencial com idempotência

### 4.3. Segurança

- **Network:** VPC com subnets privadas para banco de dados
- **IAM:** Princípio do menor privilégio para cada função/container
- **Criptografia:** TLS/SSL em trânsito, encryption at rest em RDS/DynamoDB

### 4.4. Custo-Efetividade

- **Serverless:** Pagamento consumo real (Lambda, DynamoDB under-demand)
- **Reserved Instances:** Para componentes com workload previsível
- **Auto-scaling:** Minimização de recursos ociosos

---

## 5. Tecnologias Complementares

| Componente | Tecnologia | Justificativa |
|---|---|---|
| Version Control | Git + GitHub | Rastreabilidade e CI/CD |
| IaC | Terraform / CloudFormation | Infraestrutura como código |
| CI/CD | GitHub Actions / AWS CodePipeline | Automação de deploy |
| Containerização | Docker | Portabilidade |
| Orquestração (alternativa) | Kubernetes (EKS) | Para clusters complexos |

---

## 6. Decisões de Design

### 6.1. Por que Serverless + Containers?

- **Serverless (Lambda):** Ideal para APIs de baixa latência, processamento event-driven e prototipagem rápida
- **Containers (ECS):** Necessário para serviços stateful, processamento pesado ou compatibilidade legada

A escolha entre ambos depende do perfil de carga de trabalho específico.

### 6.2. Por que RDS + DynamoDB?

- **RDS:** Transações ACID, joins complexos, índices relacionais
- **DynamoDB:** Escalabilidade ilimitada, latência previsível, alta throughput

Abordagem polyglot data persists, não exclusivamente relacional.

---

## 7. Próximos Passos

1. **Validação com Stakeholders:** Confirmar requisitos de SLA e tolerância a falhas
2. **Prototipagem:** Implementar PoC (Proof of Concept) com componentes críticos
3. **Teste de Carga:** Validar escalabilidade com ferramentas (JMeter, Locust)
4. **Detalhamento de Segurança:** Realizar threat modeling e security audit
5. **Plano de Migração:** Estratégia de rollout em ambientes dev/staging/prod

---

**Versão:** 1.0 | **Status:** Proposta de Arquitetura | **Data:** Maio/2026
