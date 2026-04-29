# Dependências Planejadas - Backend Rust

Este arquivo documenta as dependências que serão adicionadas ao workspace conforme o desenvolvimento progride.

## Como Usar

### Dependências

Quando precisar adicionar uma dependência, copie a linha correspondente para o `Cargo.toml` na seção `[workspace.dependencies]`.

Nos crates individuais, use:

```toml
[dependencies]
axum.workspace = true
shared = { path = "../shared" }
```

### Lints (Já Configurado)

Todos os crates devem herdar os lints do workspace adicionando:

```toml
[lints]
workspace = true
```

**Lints ativos:**

- `unsafe_code = "forbid"` → Zero unsafe code (erro fatal)
- `unused_must_use = "deny"` → Result/Option devem ser tratados
- `missing_docs = "warn"` → Funções públicas precisam de documentação
- `clippy::all` e `clippy::pedantic` → ~800 regras de boas práticas

---

## Web Framework

```toml
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace"] }
```

**Uso:** `api/` (HTTP server principal)

---

## Database

```toml
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-rustls", "migrate", "uuid", "chrono"] }
redis = { version = "0.24", features = ["tokio-comp", "connection-manager"] }
```

**Uso:**

- `shared/` (pool de conexões)
- `auth/`, `users/`, `biometric/`, `certification/` (queries)

---

## Serialization

```toml
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

**Uso:** Todos os crates (structs, API responses)

---

## Authentication & Security

```toml
jsonwebtoken = "9"
argon2 = "0.5"
uuid = { version = "1.6", features = ["v4", "serde"] }
```

**Uso:**

- `auth/` (JWT, password hashing, session IDs)
- `users/` (user IDs)

---

## Cryptography

```toml
aes-gcm = "0.10"
rand = "0.8"
```

**Uso:** `storage/` (AES-256 encryption para dados biométricos)

---

## Error Handling

```toml
anyhow = "1.0"
thiserror = "1.0"
```

**Uso:**

- `anyhow` → erros genéricos em aplicações (`api/`, `cli/`)
- `thiserror` → error types customizados em libs (`shared/errors.rs`)

---

## Async

```toml
async-trait = "0.1"
```

**Uso:** Traits assíncronas em `repository.rs` e `service.rs`

---

## Logging & Tracing

```toml
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
```

**Uso:** `api/` (observabilidade, logs estruturados)

---

## Date & Time

```toml
chrono = { version = "0.4", features = ["serde"] }
```

**Uso:** Timestamps em `models/` (created_at, updated_at)

---

## Config

```toml
dotenvy = "0.15"
```

**Uso:** `api/` (carregar variáveis de ambiente)

---

## Pagamentos (Futuro)

```toml
# Stripe
stripe-rust = "0.22"

# Mercado Pago
reqwest = { version = "0.11", features = ["json"] }
```

**Uso:** `billing/` (integrações de pagamento)

---

## Email (Futuro)

```toml
lettre = { version = "0.11", features = ["tokio1-rustls-tls"] }
```

**Uso:** `notifications/` (envio de emails)

---

## Testes

```toml
# Dev dependencies (adicionar em [workspace.dev-dependencies])
tokio-test = "0.4"
mockall = "0.12"
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-rustls", "migrate"] }
```

**Uso:** `tests/` (mocks, fixtures)

---

## Validação

```toml
validator = { version = "0.16", features = ["derive"] }
```

**Uso:** Validação de inputs em `models/` e `routes/`

---

## CLI Tools (Futuro)

```toml
clap = { version = "4", features = ["derive"] }
```

**Uso:** `cli/` (argumentos de linha de comando)

---

## Observações

- **Edition:** 2024 (Rust 1.85+)
- **MSRV:** 1.75+ (para features modernas)
- **Profiles:** Release otimizado com LTO thin, strip = true

---

## Estratégia de Adição

1. **Fase 1 (MVP):** serde, tokio, axum, sqlx, uuid, argon2, jsonwebtoken
2. **Fase 2 (Core):** aes-gcm, redis, tracing, chrono
3. **Fase 3 (Features):** stripe, mercado pago, lettre, validator
4. **Fase 4 (Tooling):** clap, observabilidade avançada
