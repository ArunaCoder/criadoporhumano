# AGENTS.md — Diretrizes para Agentes de IA

## Visão Geral do Projeto

- Monorepo Híbrido: Backend em Rust (`services/*`) e Frontend em Vanilla TypeScript (`apps/*`).
- Bibliotecas compartilhadas em `libs/*`.
- Foco: Performance, segurança (Rust) e controle total (Vanilla TS, sem frameworks pesados).
- Estamos usando Rust edition 2024. Leia [The_Rust_Edition_Guide_Rust_2024](The_Rust_Edition_Guide_Rust_2024.md) para verificar se o código sugerido ou gerado está atualizado.

---

## 🎯 FASE DO PROJETO

**FASE ATUAL: `estudo`**

### Opções de Fase

- **`estudo`**: Aprendizado progressivo, validações incrementais
- **`producao`**: Checklist de segurança completo obrigatório

### Comportamento por Fase

#### FASE: `estudo`

O usuário está **aprendendo** e o código permanecerá em desenvolvimento por um tempo. Nesta fase:

- ✅ **Código continua profissional**: Error handling, tipos corretos, lógica clara
- ⚠️ **Validações de segurança são incrementais**: Nem todas precisam ser implementadas de uma vez
- 🤔 **Sempre pergunte antes**: "Quais validações de segurança você quer aplicar agora?"
  - Exemplo: "Aplicar prepared statements? Rate limiting? Path traversal protection?"
  - Dê opções claras baseadas no tipo de código
- 🚀 **Autonomia do agente**: Se aplicar o checklist completo for **simples** (não aumentar complexidade significativamente), pode aplicar e **explicar o que fez**
- 📚 **Foco pedagógico**: Explique **por que** cada validação importa, não apenas "faça assim"

**Exemplo de pergunta:**

> "Vou criar uma função de busca no banco. Quer que eu aplique:
>
> - 1 Prepared statements (proteção SQL injection)
> - 2 Limite de resultados (proteção DoS)
> - 3 Timeout de query
> - 4 Validação de autorização
>
> Ou prefere começar simples e adicionar depois?"

#### FASE: `producao`

O código está sendo preparado para deploy real. Nesta fase:

- ✅ **Checklist de segurança COMPLETO**: Todas as validações obrigatórias
- ✅ **Consulta obrigatória**: Sempre ler o checklist antes de escrever código crítico
- ✅ **Sem atalhos**: Zero tolerância para código inseguro
- ✅ **Testes de segurança**: Boundary tests, injection tests, concurrency tests

---

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

- **NÍVEL PROFISSIONAL OBRIGATÓRIO (todas as fases)**: Todo código gerado — funções, métodos, testes, soluções — deve ter qualidade profissional. Sempre implemente error handling correto, tipos fortes, e lógica clara. **A FASE afeta apenas quais validações de segurança aplicar, não a qualidade do código.**
- **Rust:** Siga o `clippy`. Use tipos fortes e evite `unwrap()` em código de produção.
- **TypeScript:** Vanilla TS apenas. Proibido JSX/React a menos que solicitado.
- **Idioma de código**: Nome de funções, métodos, variáveis... tudo em inglês.
- **Documentação:** Comentários em português nos arquivos de código; documentação de apoio em português.

## Comandos Autorizados

- Rust: `cargo build`, `cargo test`, `cargo clippy`.
- TS: `npm run build` (via tsc -b), `npm install`.

## Checklist de Desenvolvimento Seguro

Consulte [`docs/security/checklist-desenvolvimento-seguro.md`](docs/security/checklist-desenvolvimento-seguro.md) conforme a **FASE** atual do projeto.

### Comportamento por FASE

**FASE `estudo`:**

- Pergunte ao usuário quais validações aplicar antes de codar
- Se aplicar o checklist completo for simples, aplique e explique
- Foco pedagógico: explique **por que** cada validação importa

**FASE `producao`:**

- Checklist completo é **obrigatório**
- Leia a seção relevante antes de escrever código crítico
- Sem atalhos ou validações pendentes

### Índice Rápido por Tipo de Código

Use este índice para ler **apenas a seção relevante** antes de codar:

- **Funções de Banco de Dados** → Linhas 11-81
  - Prepared statements, transações atômicas, TOCTOU em queries
  - Exemplo: `fn get_user()`, `fn transfer_balance()`

- **Endpoints HTTP / APIs** → Linhas 83-168
  - Validação de input, autorização (IDOR), rate limiting, erros opacos
  - Exemplo: `async fn delete_invoice()`, `async fn create_user()`

- **Manipulação de Arquivos** → Linhas 170-274
  - Path traversal, validação de magic bytes, upload seguro
  - Exemplo: `fn serve_file()`, `async fn handle_upload()`

- **Processamento de Input do Usuário** → Linhas 276-344
  - NewTypes (type-driven security), validação de limites
  - Exemplo: `struct Email`, `fn set_quantity()`

- **Estado Compartilhado / Concorrência** → Linhas 346-442
  - Mutex, Atomics, TOCTOU em memória, deadlock prevention
  - Exemplo: `static COUNTER`, `fn withdraw()`

- **Autenticação e Autorização** → Linhas 444-509
  - Hash de senhas (Argon2), timing-safe comparison, separação auth/authz
  - Exemplo: `fn hash_password()`, `async fn update_document()`

- **Serialização / Exposição de Dados** → Linhas 511-568
  - DTOs separados, skip de campos sensíveis, whitelist
  - Exemplo: `struct UserResponse`, `fn get_user()`

- **Logging e Observabilidade** → Linhas 570-630
  - Logs estruturados (JSON), correlation IDs, sanitização de PII
  - Exemplo: `async fn process_payment()` com tracing

- **Testes e Validação** → Linhas 632-672
  - Boundary testing, testes de injeção, fuzzing
  - Exemplo: `test_quantity_validation()`, `test_path_traversal()`

### Workflow de Uso

1. **Identifique o tipo de código** que vai escrever
2. **Leia as linhas correspondentes** no checklist (use `read_file` com startLine/endLine)
3. **Aplique o checklist** durante a escrita
4. **Valide** antes de submeter código

**Exemplo de uso da ferramenta:**

```
read_file(
    filePath="docs/security/checklist-desenvolvimento-seguro.md",
    startLine=11,
    endLine=81
)
```

### Regra de Ouro

Se você está escrevendo código que:

- Acessa dados externos (DB, filesystem, network)
- Processa input do usuário
- Lida com estado mutável
- Expõe APIs ou dados

**→ FASE `estudo`**: Consulte o checklist e pergunte quais validações aplicar
**→ FASE `producao`**: Consulta ao checklist é **obrigatória** antes de codar
