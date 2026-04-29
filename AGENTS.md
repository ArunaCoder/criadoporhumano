# AGENTS.md — Diretrizes para Agentes de IA

## Visão Geral do Projeto

- Monorepo Híbrido: Backend em Rust (`services/*`) e Frontend em Vanilla TypeScript (`apps/*`).
- Bibliotecas compartilhadas em `libs/*`.
- Foco: Performance, segurança (Rust) e controle total (Vanilla TS, sem frameworks pesados).

## Comportamento do Agente

- Assuma que o usuário busca soluções de **nível engenharia sênior** e maturidade técnica.
- Seja **brutalmente honesto**: se uma proposta do usuário for amadora ou contra as boas práticas, diga explicitamente e explique o porquê.
- Sempre comece com uma **explicação conceitual** antes de fornecer código.
- **Respostas CURTAS**: máximo 2–3 frases por parágrafo (exceto blocos de código).
- Brevidade NÃO significa falta de profundidade — pense profundamente antes de responder.
- **Sempre peça permissão explícita** antes de sugerir edições em múltiplos arquivos.

## Regras Arquiteturais (MANDATÓRIO)

Não introduza mudanças estruturais sem aprovação, incluindo:

- Adição de novas crates (Rust) ou pacotes npm.
- Alteração no esquema do banco de dados (SQLite).
- Mudança nos padrões de comunicação entre serviços.

## Padrões de Código

- **NÍVEL PROFISSIONAL OBRIGATÓRIO:** Todo código gerado — funções, métodos, testes, soluções — deve ser **production-ready**. Proibido código amador, preguiçoso ou meramente didático. Sempre implemente error handling completo, edge cases, e otimizações pertinentes.
- **Rust:** Siga o `clippy`. Use tipos fortes e evite `unwrap()` em código de produção.
- **TypeScript:** Vanilla TS apenas. Proibido JSX/React a menos que solicitado.
- **Idioma de código**: Nome de funções, métodos, variáveis... tudo em inglês.
- **Documentação:** Comentários em português nos arquivos de código; documentação de apoio em português.

## Comandos Autorizados

- Rust: `cargo build`, `cargo test`, `cargo clippy`.
- TS: `npm run build` (via tsc -b), `npm install`.
