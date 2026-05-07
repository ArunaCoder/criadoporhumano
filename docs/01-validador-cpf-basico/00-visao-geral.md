# 🛡️ Visão Geral: Soberania Total (CPF Validator)

## Objetivo

Criar um **mini projeto profissional end-to-end** de validação de CPF usando apenas a **Rust Standard Library** para o backend, eliminando dependências de frameworks externos.

## Filosofia: "Quero ser engenheiro, não gestor de bibliotecas"

Este projeto substitui frameworks de alto nível por implementações manuais. O objetivo é **entender** como sistemas funcionam por baixo, não apenas usar abstrações prontas.

**Por que isso importa:**

- Frameworks escondem complexidade essencial
- Dependências externas = superfície de ataque (Log4j, left-pad)
- Binários gigantes para tarefas simples
- Você fica refém de decisões de terceiros

## Arquitetura

```
┌─────────────────────────────────────────┐
│   Frontend (Vanilla TS + HTML + CSS)   │
│   Embutido no binário via include_str!  │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│      HTTP Server (TCP + Parser Manual)  │
│      Router Manual (match expressions)  │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│   Validador de CPF (backend/shared)    │
│   Algoritmo puro, sem dependências      │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│   Deploy: Docker FROM scratch (~2-5MB)  │
│   Binário estático (MUSL) + VPS         │
└─────────────────────────────────────────┘
```

## Stack Tecnológica

### Backend

- **Linguagem:** Rust (apenas std lib)
- **Networking:** `std::net::TcpListener`
- **HTTP:** Parser manual de strings
- **Compilação:** MUSL target (binário estático)

### Frontend

- **HTML5:** Estrutura semântica
- **CSS3:** Design minimalista e responsivo
- **TypeScript:** Vanilla (sem frameworks)
- **Build:** esbuild (transpilação rápida)

### Deploy

- **Docker:** Multi-stage build + `FROM scratch`
- **Infra:** VPS (512MB RAM suficiente)
- **HTTPS (opcional):** Caddy (auto-SSL)

## Fluxo de Trabalho

1. **Camada 1:** Implementar servidor HTTP baixo nível (Passos 1-13)
2. **Camada 2:** Adicionar routing e lógica de validação (Passos 14-19)
3. **Camada 3:** Criar frontend e embedar no binário (Passos 20-26)
4. **Camada 4:** Dockerizar e fazer deploy em VPS (Passos 27-35)
5. **Camada 5 (Opcional):** Otimizações avançadas para produção (thread pool, zero-copy, async)

## Diferencial

Ao final deste projeto, você terá:

- ✅ Entendimento profundo de HTTP e TCP
- ✅ Capacidade de debugar problemas de rede
- ✅ Conhecimento sólido de vulnerabilidades web (DoS, path traversal, injection)
- ✅ Binário auto-contido de ~2-3MB
- ✅ Sistema deployável em qualquer Linux
- ✅ Zero dependências de runtime
- ✅ Implementação production-ready com validações de segurança

## Princípios de Segurança

Este projeto implementa **segurança em profundidade**:

1. **Proteção contra DoS:** Limites em tamanho de linha, headers e body
2. **Validação rigorosa:** Method whitelist, HTTP version check, path traversal protection
3. **Resource management:** Timeouts (read/write), Connection: close forçado, file descriptor monitoring
4. **Princípio do menor privilégio:** Container rodando como usuário não-root
5. **Defense in depth:** Múltiplas camadas de validação (cliente + servidor)

## Status

**Em progresso** - Ver arquivos:

- **Fase 1 (Fundamentos):** `01-*.md` a `04-*.md` para checklists detalhados
- **Fase 2 (Otimizações):** `05-otimizacoes-avancadas.md` para thread pool, zero-copy, e async
