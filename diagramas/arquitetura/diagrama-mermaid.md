# Diagrama da Arquitetura — Formato Mermaid

## Nota
Este arquivo documenta o código Mermaid para visualizar a arquitetura. 
O diagrama pode ser visualizado em:
- [Mermaid Live Editor](https://mermaid.live)
- [Draw.io](https://draw.io)
- VS Code com extensão Markdown Preview Mermaid Support

---

## 1. Diagrama de Arquitetura — C4 Context Level

```mermaid
graph LR
    USER["👤 Usuário<br/>(Navegador)"]
    CDN["☁️ AWS CloudFront<br/>(CDN)"]
    S3["💾 AWS S3<br/>(SPA - React/Next.js)"]
    APIGW["🔌 API Gateway<br/>(RESTful)"]
    LAMBDA["⚡ AWS Lambda<br/>(Serviços)"]
    ECS["📦 AWS ECS/Fargate<br/>(Microsserviços)"]
    COGNITO["🔐 AWS Cognito<br/>(AuthN/AuthZ)"]
    
    USER -->|HTTPS| CDN
    CDN -->|Cache estático| S3
    S3 -->|Requisições API| APIGW
    APIGW -->|Autentica| COGNITO
    APIGW -->|Roteia para| LAMBDA
    APIGW -->|Roteia para| ECS
```

---

## 2. Diagrama Detalhado — C4 Container Level

```mermaid
graph TB
    subgraph CLIENT["📱 Cliente"]
        BROWSER["🌐 Navegador<br/>(React/Next.js SPA)"]
    end
    
    subgraph CDN_LAYER["☁️ CDN & Hospedagem"]
        CLOUDFRONT["CloudFront<br/>(CDN Global)"]
        S3_STATIC["S3<br/>(Conteúdo Estático)"]
    end
    
    subgraph GATEWAY["🔌 Roteamento & Autenticação"]
        APIGW_MAIN["API Gateway<br/>(Orquestração)"]
        COGNITO_AUTH["AWS Cognito<br/>(Autenticação)"]
    end
    
    subgraph BACKEND["💼 Camada de Negócio"]
        LAMBDA_SYNC["AWS Lambda<br/>(APIs Síncronas)"]
        ECS_SERVICE["AWS ECS/Fargate<br/>(Microsserviços)"]
        SQS_QUEUE["AWS SQS<br/>(Fila Assíncrona)"]
        SNS_TOPIC["AWS SNS<br/>(Pub/Sub)"]
    end
    
    subgraph DATABASE["💾 Camada de Dados"]
        RDS["RDS PostgreSQL<br/>(Relacional)"]
        DYNAMODB["DynamoDB<br/>(NoSQL)"]
        ELASTICACHE["ElastiCache<br/>(Cache)"]
    end
    
    subgraph MONITORING["📊 Observabilidade"]
        CLOUDWATCH["CloudWatch Logs<br/>(Agregação)"]
        METRICS["CloudWatch Metrics<br/>(Performance)"]
        XRAY["X-Ray<br/>(Distributed Tracing)"]
        ALARMS["CloudWatch Alarms<br/>(Alertas)"]
    end
    
    %% Fluxo de Requisição
    BROWSER -->|HTTPS| CLOUDFRONT
    CLOUDFRONT -->|Serve Cache| S3_STATIC
    S3_STATIC -->|Conteúdo| BROWSER
    
    BROWSER -->|API Call| APIGW_MAIN
    APIGW_MAIN -->|Valida Token| COGNITO_AUTH
    APIGW_MAIN -->|Login| COGNITO_AUTH
    
    APIGW_MAIN -->|Síncrono| LAMBDA_SYNC
    APIGW_MAIN -->|Roteamento| ECS_SERVICE
    
    LAMBDA_SYNC -->|Lê/Escreve| RDS
    LAMBDA_SYNC -->|Cache/Session| DYNAMODB
    ECS_SERVICE -->|Lê/Escreve| RDS
    ECS_SERVICE -->|Pub Event| SNS_TOPIC
    
    SNS_TOPIC -->|Dispara| LAMBDA_SYNC
    SNS_TOPIC -->|Consome| SQS_QUEUE
    SQS_QUEUE -->|Worker| ECS_SERVICE
    
    ELASTICACHE -->|Cache Local| LAMBDA_SYNC
    ELASTICACHE -->|Cache Local| ECS_SERVICE
    
    %% Observabilidade
    LAMBDA_SYNC -->|Logs| CLOUDWATCH
    ECS_SERVICE -->|Logs| CLOUDWATCH
    CLOUDWATCH -->|Processa| METRICS
    LAMBDA_SYNC -->|Trace| XRAY
    ECS_SERVICE -->|Trace| XRAY
    METRICS -->|Triggered| ALARMS
    
    CLOUDWATCH -->|Visualiza| BROWSER
```

---

## 3. Diagrama de Fluxo de Requisição

```mermaid
sequenceDiagram
    participant User as 👤 Usuário
    participant CF as ☁️ CloudFront
    participant S3 as 💾 S3
    participant APIGW as 🔌 API Gateway
    participant Auth as 🔐 Cognito
    participant Lambda as ⚡ Lambda
    participant RDS as 📊 RDS
    participant CW as 📈 CloudWatch
    
    User->>CF: 1. Acessa SPA
    CF->>S3: 2. Busca assets
    S3-->>CF: 3. Retorna HTML/JS/CSS
    CF-->>User: 4. Entrega com cache
    
    User->>APIGW: 5. POST /api/login
    APIGW->>Auth: 6. Valida credenciais
    Auth-->>APIGW: 7. Retorna JWT
    APIGW-->>User: 8. Token em resposta
    
    User->>APIGW: 9. GET /api/data (com JWT)
    APIGW->>Auth: 10. Valida token
    Auth-->>APIGW: 11. Token válido
    APIGW->>Lambda: 12. Invoca função
    Lambda->>RDS: 13. Busca dados
    RDS-->>Lambda: 14. Retorna resultados
    Lambda-->>APIGW: 15. Dados processados
    APIGW-->>User: 16. JSON response
    
    Lambda->>CW: 17. Log de execução
    CW->>CW: 18. Agrega métricas
```

---

## 4. Diagrama de Escalabilidade

```mermaid
graph LR
    LB["⚖️ Load Balancer<br/>(Auto Scaling)"]
    
    subgraph AS1["AZ 1"]
        L1["Lambda 1"]
        E1["Container 1"]
    end
    
    subgraph AS2["AZ 2"]
        L2["Lambda 2"]
        E2["Container 2"]
    end
    
    subgraph AS3["AZ 3"]
        L3["Lambda 3"]
        E3["Container 3"]
    end
    
    subgraph DB["Multi-AZ Database"]
        PRIMARY["RDS Primary<br/>(AZ 1)"]
        REPLICA1["Read Replica<br/>(AZ 2)"]
        REPLICA2["Read Replica<br/>(AZ 3)"]
    end
    
    LB -->|Distribui| L1
    LB -->|Distribui| L2
    LB -->|Distribui| L3
    LB -->|Distribui| E1
    LB -->|Distribui| E2
    LB -->|Distribui| E3
    
    L1 -->|Read/Write| PRIMARY
    L2 -->|Read| REPLICA1
    L3 -->|Read| REPLICA2
    
    E1 -->|Read/Write| PRIMARY
    E2 -->|Read| REPLICA1
    E3 -->|Read| REPLICA2
    
    PRIMARY -->|Replica| REPLICA1
    PRIMARY -->|Replica| REPLICA2
```

---

## 5. Diagrama de Comunicação Assíncrona

```mermaid
graph LR
    API["API"]
    PRODUCER["Producer<br/>(Lambda/Container)"]
    SNS["AWS SNS<br/>(Topic)"]
    SQS["AWS SQS<br/>(Queue)"]
    CONSUMER1["Consumer 1<br/>(Lambda)"]
    CONSUMER2["Consumer 2<br/>(Container)"]
    
    API -->|Publish Event| PRODUCER
    PRODUCER -->|Put Message| SNS
    SNS -->|Fan-out| SQS
    SNS -->|Direct Sub| CONSUMER1
    SQS -->|Pull| CONSUMER2
```

---

## 6. Diagrama de Segurança

```mermaid
graph TB
    USER["👤 Usuário"]
    INTERNET["🌐 Internet (Pública)"]
    WAF["🛡️ AWS WAF<br/>(DDoS Mitigation)"]
    APIGW["API Gateway<br/>(Rate Limiting)"]
    
    subgraph VPC["🔒 VPC (Privada)"]
        direction LR
        ALB["ALB<br/>(Internal)"]
        
        subgraph PUBLIC["Public Subnet"]
            NAT["NAT Gateway"]
        end
        
        subgraph PRIVATE["Private Subnet"]
            LAMBDA_PRIV["Lambda<br/>(Private)"]
            ECS_PRIV["ECS<br/>(Private)"]
        end
        
        subgraph DB_SUBNET["DB Subnet (Very Private)"]
            RDS_PRIV["RDS<br/>(No Internet)"]
            DYNA["DynamoDB<br/>(VPC Endpoint)"]
        end
    end
    
    USER -->|HTTPS| INTERNET
    INTERNET -->|Validado| WAF
    WAF -->|Rate Limited| APIGW
    APIGW -->|Roteia| ALB
    ALB -->|Invoca| LAMBDA_PRIV
    ALB -->|Invoca| ECS_PRIV
    LAMBDA_PRIV -->|IAM Role| RDS_PRIV
    ECS_PRIV -->|IAM Role| RDS_PRIV
    LAMBDA_PRIV -->|VPC Endpoint| DYNA
```

---

## 7. Diagrama de CI/CD

```mermaid
graph LR
    DEV["👨‍💻 Desenvolvedor"]
    GIT["📦 GitHub<br/>(Repository)"]
    CI["⚙️ GitHub Actions<br/>(CI)"]
    REGISTRY["📦 ECR<br/>(Container Registry)"]
    
    subgraph ENVS["Ambientes de Deploy"]
        DEV_ENV["Development"]
        STAG_ENV["Staging"]
        PROD_ENV["Production"]
    end
    
    DEV -->|Git Push| GIT
    GIT -->|Webhook| CI
    CI -->|Build & Test| REGISTRY
    CI -->|Deploy| DEV_ENV
    DEV_ENV -->|Approval| STAG_ENV
    STAG_ENV -->|Approval| PROD_ENV
```

---

## 8. Padrões de Consumo do Diagrama

Os diagramas acima podem ser:

1. **Copiados diretamente** para [Mermaid Live Editor](https://mermaid.live)
2. **Renderizados em VS Code** com a extensão `Markdown Preview Mermaid Support`
3. **Convertidos para PNG/SVG** usando ferramentas online ou CLI (`mmdc -i diagrama.mmd -o diagrama.png`)

---

**Gerado em:** Maio/2026 | **Versão:** 1.0
