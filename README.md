# Iniciação Científica - Engenharia de Software

Projeto final integrador da disciplina de Iniciação Científica, com foco em arquitetura cloud-native, microsserviços, serverless, segurança e escalabilidade.

## Objetivo

Organizar a proposta final do semestre em um repositório técnico-acadêmico com documentação, referências, diagramas e material de apoio para apresentação e entrega.

## Estrutura do Repositório

```text
/docs
/diagramas
/publicacao
/artigos
/referencias
/src
/data
README.md
```

## Conteúdo principal

- `docs/relatorios/projeto-final-integrador.md`: documento técnico-científico final.
- `diagramas/arquitetura/descricao-arquitetura.md`: consolidação arquitetural do sistema.
- `diagramas/arquitetura/diagrama-mermaid.md`: diagrama em Mermaid com visão contextual, de containers, fluxo, escalabilidade, segurança e CI/CD.
- `referencias/bibliografia/REFERENCIAS-ABNT.md`: referências acadêmicas e técnicas em formato ABNT.
- `publicacao/tarefa07-congresso.md`: registro da Tarefa 07, checklist de prazos e mensagem para revisão.
- `artigos/resumo-expandido.pdf`: resumo expandido preparado para o III Congresso UniSENAI-SP.
- `artigos/resumo-expandido.docx`: versão editável do resumo expandido.
- `artigos/resumo-expandido.md`: fonte textual do resumo expandido.
- `METODO-DE-TRABALHO.md`: método de trabalho adotado no projeto.

## Tecnologias e Conceitos

- React ou Next.js para front-end
- AWS CloudFront e S3 para distribuição de conteúdo
- API Gateway para integração
- AWS Lambda e ECS/Fargate para processamento
- RDS e DynamoDB para persistência
- Cognito para autenticação
- CloudWatch e X-Ray para observabilidade
- Docker, Git e GitHub para organização e versionamento

## Arquitetura da Solução

A solução segue uma abordagem cloud-native, com front-end desacoplado, backend híbrido e persistência poliglota. O desenho privilegia escalabilidade horizontal, segurança por camadas e comunicação assíncrona quando apropriado.

## Diagramas

- `diagramas/arquitetura/diagrama-mermaid.md`
- `diagramas/arquitetura/descricao-arquitetura.md`

## Referências Principais

- Newman, *Building Microservices*
- Cerny et al., *On Microservices Architecture*
- Shafiei et al., *Serverless Computing: A Survey of Opportunities, Challenges and Applications*
- AWS Well-Architected Framework
- AWS Lambda Developer Guide

## Tarefa 07 - Congresso UniSENAI-SP

O resumo expandido foi preparado como trabalho em desenvolvimento, sem inventar resultados experimentais. O arquivo final contém contexto, problema, objetivos, justificativa, revisão de literatura, metodologia, resultados parciais, discussões, conclusão preliminar e referências.

O prazo interno para envio aos orientadores Deivison Shindi Takatu e Glauco Todesco é `18/09/2026`. O prazo oficial de submissão informado na atividade é `25/09/2026`. A inscrição como apresentador, presencial ou online, deve ser realizada pelo autor na plataforma do evento até `16/10/2026`.

Consulte [publicacao/tarefa07-congresso.md](publicacao/tarefa07-congresso.md) para o checklist completo e a mensagem de revisão.

## Organização das Pastas

- `docs`: artigos, relatórios e apresentações
- `diagramas`: diagramas arquiteturais e de modelagem
- `referencias`: bibliografia, BibTeX e PDFs de apoio
- `src`: protótipos e experimentos
- `data`: dados brutos e tratados
- `scripts`: automações e setup do projeto
