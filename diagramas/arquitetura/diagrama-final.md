# Diagrama Final da Arquitetura

```mermaid
flowchart LR
    U[Usuário]
    CF[CloudFront]
    S3[S3 - Front-end estático]
    GW[API Gateway]
    AUTH[Cognito]
    L1[Lambda - APIs e eventos]
    ECS[ECS/Fargate - Serviços de domínio]
    RDS[RDS PostgreSQL]
    DDB[DynamoDB]
    MQ[SQS / SNS]
    OBS[CloudWatch / X-Ray]

    U --> CF --> S3
    U --> GW
    GW --> AUTH
    GW --> L1
    GW --> ECS
    L1 --> RDS
    L1 --> DDB
    ECS --> RDS
    ECS --> MQ
    MQ --> L1
    L1 --> OBS
    ECS --> OBS
```

## Leitura do diagrama

- O front-end é distribuído via CDN e armazenado em objeto estático.
- O API Gateway centraliza o tráfego e a política de acesso.
- Cognito atua como serviço de identidade.
- Lambda cobre automações curtas, endpoints e eventos.
- ECS/Fargate cobre rotinas mais longas e serviços de domínio.
- RDS e DynamoDB formam a persistência híbrida.
- SQS/SNS suportam integração assíncrona.
- CloudWatch e X-Ray sustentam observabilidade e rastreamento.
