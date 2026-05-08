# Checklist de Desenvolvimento Seguro: Guia de Campo

## Introdução

Um engenheiro sênior não escreve código e depois "pensa em segurança". A segurança é um **subproduto do design**.

Este documento é um **guia de campo** — consulte antes de escrever cada tipo de código. Segurança não é checklist de auditoria, é checklist de **desenvolvimento**.

---

## 🗄️ Funções que Acessam o Banco de Dados

### Checklist Obrigatório

- [ ] **Parâmetros tipados**: Use tipos específicos (`UserId`, `Email`), não `String` genérico
- [ ] **Prepared statements**: SEMPRE. Nunca concatene SQL com variáveis
- [ ] **Limite de resultados**: Todo `SELECT` deve ter `LIMIT`, mesmo que seja 10.000
- [ ] **Transações atômicas**: Operações de read-then-write devem estar em uma transação
- [ ] **Timeout**: Configure timeout de query (ex: 5s para reads, 30s para writes)
- [ ] **Não exponha erros de DB**: Retorne `AppError::DatabaseError`, não a mensagem do SQLite/Postgres
- [ ] **Valide autorização**: Não basta WHERE id = ?; precisa WHERE id = ? AND user_id = ?

### Exemplo: ERRADO ❌

```rust
fn get_user(email: String) -> Result<User, String> {
    // ❌ SQL injection possível
    let query = format!("SELECT * FROM users WHERE email = '{}'", email);

    // ❌ Sem limite de resultados
    // ❌ Retorna erro bruto do banco
    db.execute(&query)
        .map_err(|e| e.to_string())
}
```

### Exemplo: CORRETO ✅

```rust
fn get_user(email: Email) -> Result<User, AppError> {
    // ✅ Prepared statement
    let query = "SELECT id, email, created_at FROM users WHERE email = ? LIMIT 1";

    // ✅ Parâmetro tipado
    // ✅ Timeout implícito (configure no pool)
    db.query_one(query, &[&email.as_str()])
        .map_err(|_| AppError::NotFound) // ✅ Erro opaco
}
```

### Operações de Escrita

```rust
fn transfer_balance(from: UserId, to: UserId, amount: Money) -> Result<(), AppError> {
    // ✅ Transação atômica (TOCTOU protection)
    let tx = db.transaction()?;

    // ✅ UPDATE com WHERE condicional (operação atômica)
    let affected = tx.execute(
        "UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?",
        &[&amount, &from, &amount]
    )?;

    if affected == 0 {
        tx.rollback()?;
        return Err(AppError::InsufficientFunds);
    }

    tx.execute(
        "UPDATE accounts SET balance = balance + ? WHERE id = ?",
        &[&amount, &to]
    )?;

    tx.commit()?;
    Ok(())
}
```

> **Leitura relacionada:** [toc-tou.md](toc-tou.md) — Race conditions em operações de banco

---

## 🌐 Endpoints HTTP / APIs

### Checklist Obrigatório

- [ ] **Validação de input**: Valide tipo, tamanho, formato ANTES de processar
- [ ] **Limite de payload**: Configure limite de body (ex: 1MB para JSON)
- [ ] **Rate limiting**: Por IP e por usuário autenticado
- [ ] **Autenticação E autorização**: Não confunda os dois
- [ ] **Erros opacos**: `401 Unauthorized`, não "Usuário não encontrado"
- [ ] **Logs estruturados**: Registre method, path, status, duration, user_id
- [ ] **Timeout de resposta**: Handler deve ter deadline (ex: 30s)
- [ ] **Content-Type validation**: Rejeite se não for o esperado

### Exemplo: ERRADO ❌

```rust
async fn delete_invoice(id: String) -> Response {
    // ❌ Não valida autenticação
    // ❌ Não valida autorização (IDOR vulnerability)
    // ❌ String genérico (deveria ser InvoiceId)

    match db.delete(&id) {
        Ok(_) => Response::ok("Deleted"),
        // ❌ Expõe detalhes do erro
        Err(e) => Response::error(&format!("Database error: {}", e))
    }
}
```

### Exemplo: CORRETO ✅

```rust
async fn delete_invoice(
    auth: AuthToken,           // ✅ Autenticação
    id: InvoiceId,             // ✅ Tipo específico
) -> Result<Response, AppError> {
    // ✅ Autorização explícita
    let invoice = db.get_invoice(id).await?;
    if invoice.user_id != auth.user_id {
        return Err(AppError::Forbidden);
    }

    // ✅ Operação autorizada
    db.delete_invoice(id).await?;

    // ✅ Log estruturado
    info!(
        user_id = %auth.user_id,
        invoice_id = %id,
        "Invoice deleted"
    );

    Ok(Response::ok())
}
```

### Validação de Input

```rust
struct CreateUserRequest {
    email: String,
    password: String,
    name: String,
}

impl CreateUserRequest {
    fn validate(self) -> Result<ValidatedUserData, ValidationError> {
        // ✅ Validação explícita antes de processar
        let email = Email::parse(&self.email)?;

        if self.password.len() < 12 {
            return Err(ValidationError::PasswordTooShort);
        }

        if self.name.len() > 100 {
            return Err(ValidationError::NameTooLong);
        }

        Ok(ValidatedUserData { email, password: self.password, name: self.name })
    }
}
```

> **Leitura relacionada:** [logica-negocio.md](logica-negocio.md) — IDOR, DoS lógico, poluição de parâmetros

---

## 📁 Manipulação de Arquivos

### Checklist Obrigatório

- [ ] **Path traversal protection**: Valide que o path não contém `..` ou `/etc/`
- [ ] **Whitelist de extensões**: Se aceita uploads, valide extensão E magic bytes
- [ ] **Limite de tamanho**: Não aceite arquivos maiores que o necessário
- [ ] **Sanitize filename**: Remove caracteres especiais, limita comprimento
- [ ] **Permissões mínimas**: Abra arquivos com menor privilégio possível
- [ ] **Não confie no MIME type**: Cliente pode mentir, valide o conteúdo
- [ ] **Quarantine uploads**: Armazene em local temporário antes de validar

### Exemplo: ERRADO ❌

```rust
fn serve_file(path: &str) -> Result<Vec<u8>, Error> {
    // ❌ Path traversal vulnerability
    let full_path = format!("/var/www/public/{}", path);

    // ❌ Sem validação de extensão
    // ❌ Sem limite de tamanho
    std::fs::read(full_path)
}

// Ataque: serve_file("../../etc/passwd")
```

### Exemplo: CORRETO ✅

```rust
fn serve_file(path: &str) -> Result<Vec<u8>, AppError> {
    // ✅ Valida path traversal
    if path.contains("..") || path.starts_with('/') {
        return Err(AppError::InvalidPath);
    }

    // ✅ Whitelist de extensões
    let allowed = ["html", "css", "js", "png", "jpg"];
    let ext = Path::new(path)
        .extension()
        .and_then(|s| s.to_str())
        .ok_or(AppError::InvalidPath)?;

    if !allowed.contains(&ext) {
        return Err(AppError::ForbiddenFileType);
    }

    // ✅ Path canonicalização e validação
    let base = Path::new("/var/www/public");
    let full_path = base.join(path).canonicalize()
        .map_err(|_| AppError::NotFound)?;

    if !full_path.starts_with(base) {
        return Err(AppError::InvalidPath);
    }

    // ✅ Limite de tamanho (10MB)
    let metadata = std::fs::metadata(&full_path)?;
    if metadata.len() > 10 * 1024 * 1024 {
        return Err(AppError::FileTooLarge);
    }

    std::fs::read(full_path)
        .map_err(|_| AppError::NotFound)
}
```

### Upload de Arquivos

```rust
async fn handle_upload(
    filename: &str,
    content: Vec<u8>,
) -> Result<FileId, AppError> {
    // ✅ Validação de tamanho
    if content.len() > 5 * 1024 * 1024 {
        return Err(AppError::FileTooLarge);
    }

    // ✅ Sanitize filename
    let clean_name = filename
        .chars()
        .filter(|c| c.is_alphanumeric() || *c == '.' || *c == '-')
        .take(100)
        .collect::<String>();

    // ✅ Valida magic bytes (não confia na extensão)
    let file_type = infer::get(&content)
        .ok_or(AppError::UnknownFileType)?;

    if !["image/png", "image/jpeg"].contains(&file_type.mime_type()) {
        return Err(AppError::ForbiddenFileType);
    }

    // ✅ Armazena com nome aleatório (evita colisões e ataques)
    let file_id = FileId::generate();
    let storage_path = format!("/var/uploads/{}", file_id);

    std::fs::write(storage_path, content)?;

    Ok(file_id)
}
```

---

## 🔐 Processamento de Input do Usuário

### Checklist Obrigatório

- [ ] **Never trust user input**: Assume que é um ataque
- [ ] **Validação de tipo**: Use NewTypes (`Email`, `Cpf`), não `String`
- [ ] **Validação de formato**: Regex ou parser rigoroso
- [ ] **Validação de limites**: Tamanho mínimo/máximo
- [ ] **Sanitização**: Remove caracteres perigosos se necessário
- [ ] **Decode antes de validar**: Se vier URL-encoded ou Base64, decode primeiro
- [ ] **Rejeite early**: Valide no edge da aplicação (controller/handler)

### NewTypes (Type-Driven Security)

```rust
// ❌ ERRADO: Tipos primitivos não garantem nada
fn send_email(email: String) { /* ... */ }

// ✅ CORRETO: NewType garante validação
pub struct Email(String);

impl Email {
    pub fn parse(s: &str) -> Result<Self, ValidationError> {
        // ✅ Validação rigorosa
        if s.len() > 254 {
            return Err(ValidationError::EmailTooLong);
        }

        if !s.contains('@') || s.starts_with('@') || s.ends_with('@') {
            return Err(ValidationError::InvalidEmail);
        }

        // Validação adicional (regex, etc.)

        Ok(Email(s.to_lowercase()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// ✅ Se a função recebe Email, ele JÁ FOI validado
fn send_email(email: Email) { /* seguro */ }
```

### Validação de Números

```rust
fn set_quantity(qty: i32) -> Result<(), AppError> {
    // ✅ Valida limites
    if qty <= 0 {
        return Err(AppError::InvalidQuantity);
    }

    if qty > 10000 {
        return Err(AppError::QuantityTooHigh);
    }

    // ✅ Valida overflow em operações
    let total_price = qty
        .checked_mul(UNIT_PRICE)
        .ok_or(AppError::ArithmeticOverflow)?;

    Ok(())
}
```

---

## 🔄 Estado Compartilhado / Concorrência

### Checklist Obrigatório

- [ ] **Use Mutex/RwLock**: Para estado mutável compartilhado
- [ ] **Minimize critical section**: Lock apenas o necessário
- [ ] **Evite deadlocks**: Sempre adquira locks na mesma ordem
- [ ] **Atomics quando possível**: Para contadores simples
- [ ] **Imutabilidade por padrão**: Clone se precisar mutar
- [ ] **Evite shared state**: Prefira message passing (channels)
- [ ] **Invariantes claros**: Documente o que o lock protege

### Exemplo: ERRADO ❌

```rust
// ❌ Estado global mutável sem proteção
static mut COUNTER: u64 = 0;

fn increment() {
    unsafe {
        COUNTER += 1; // ❌ Race condition
    }
}
```

### Exemplo: CORRETO ✅

```rust
use std::sync::atomic::{AtomicU64, Ordering};

// ✅ Atomic para contador simples
static COUNTER: AtomicU64 = AtomicU64::new(0);

fn increment() {
    COUNTER.fetch_add(1, Ordering::Relaxed);
}
```

### Estado Complexo

```rust
use std::sync::{Arc, Mutex};

struct AppState {
    sessions: HashMap<SessionId, Session>,
}

impl AppState {
    fn new() -> Arc<Mutex<Self>> {
        Arc::new(Mutex::new(Self {
            sessions: HashMap::new(),
        }))
    }

    fn add_session(&self, session: Session) {
        // ✅ Lock apenas durante a mutação
        let mut state = self.lock().unwrap();
        state.sessions.insert(session.id, session);
        // Lock é liberado automaticamente aqui
    }
}
```

### Evite TOCTOU

```rust
// ❌ ERRADO: Check-then-use
fn withdraw(balance: &Mutex<u64>, amount: u64) -> Result<(), Error> {
    let current = *balance.lock().unwrap();
    // ⚠️ Lock liberado aqui! Outro thread pode modificar balance

    if current >= amount {
        // ❌ Race condition: balance pode ter mudado
        *balance.lock().unwrap() -= amount;
        Ok(())
    } else {
        Err(Error::InsufficientFunds)
    }
}

// ✅ CORRETO: Operação atômica
fn withdraw(balance: &Mutex<u64>, amount: u64) -> Result<(), Error> {
    let mut balance = balance.lock().unwrap();

    if *balance >= amount {
        *balance -= amount;
        Ok(())
    } else {
        Err(Error::InsufficientFunds)
    }
    // Lock liberado apenas após commit completo
}
```

> **Leitura relacionada:** [toc-tou.md](toc-tou.md) — Time-of-check to time-of-use

---

## 🔑 Autenticação e Autorização

### Checklist Obrigatório

- [ ] **Autenticação ≠ Autorização**: Separe as duas validações
- [ ] **Hash de senhas**: Use Argon2 ou bcrypt, NUNCA SHA256 direto
- [ ] **Salt único**: Um salt por senha (libraries fazem isso automaticamente)
- [ ] **Timing-safe comparison**: Para comparar hashes/tokens
- [ ] **Token expiration**: Tokens devem expirar (ex: 1h para access, 7d para refresh)
- [ ] **HTTPS obrigatório**: Nunca envie credenciais em HTTP
- [ ] **Logout = invalidação**: Logout deve remover o token do servidor

### Hash de Senhas

```rust
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::SaltString;

fn hash_password(password: &str) -> Result<String, Error> {
    // ✅ Argon2 com salt aleatório
    let salt = SaltString::generate(&mut rand::thread_rng());
    let argon2 = Argon2::default();

    let hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|_| Error::HashingFailed)?;

    Ok(hash.to_string())
}

fn verify_password(password: &str, hash: &str) -> Result<bool, Error> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|_| Error::InvalidHash)?;

    // ✅ Timing-safe comparison
    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}
```

### Autorização (Resource-Level)

```rust
async fn update_document(
    auth: AuthToken,
    doc_id: DocumentId,
    content: String,
) -> Result<(), AppError> {
    // ✅ Autenticação já validada (pelo middleware)

    // ✅ Busca o recurso
    let doc = db.get_document(doc_id).await?;

    // ✅ Valida autorização explicitamente
    if doc.owner_id != auth.user_id {
        return Err(AppError::Forbidden);
    }

    // ✅ Operação autorizada
    db.update_document(doc_id, content).await?;
    Ok(())
}
```

---

## 📤 Serialização / Exposição de Dados

### Checklist Obrigatório

- [ ] **DTO separado**: Não exponha entidades do DB diretamente
- [ ] **Skip de campos sensíveis**: Senhas, tokens, IDs internos
- [ ] **Whitelist de campos**: Nunca `SELECT *` + serializar tudo
- [ ] **Sanitize output**: Escape HTML se for renderizar no frontend
- [ ] **Content-Type correto**: `application/json` com charset UTF-8
- [ ] **Não exponha stack traces**: Em produção, retorne erro genérico

### Exemplo: ERRADO ❌

```rust
#[derive(Serialize)]
struct User {
    id: i64,
    email: String,
    password_hash: String,  // ❌ Expõe hash
    api_key: String,        // ❌ Expõe credencial
}

fn get_user(id: i64) -> Json<User> {
    // ❌ Retorna tudo, incluindo dados sensíveis
    Json(db.get_user(id))
}
```

### Exemplo: CORRETO ✅

```rust
// ✅ DTO para resposta
#[derive(Serialize)]
struct UserResponse {
    id: UserId,
    email: String,
    created_at: String,
    // ✅ Sem campos sensíveis
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            created_at: user.created_at.to_rfc3339(),
        }
    }
}

fn get_user(id: UserId) -> Result<Json<UserResponse>, AppError> {
    let user = db.get_user(id)?;
    // ✅ Conversão explícita para DTO
    Ok(Json(UserResponse::from(user)))
}
```

---

## 🔍 Logging e Observabilidade

### Checklist Obrigatório

- [ ] **Logs estruturados**: JSON, não texto livre
- [ ] **Correlation ID**: Em sistemas distribuídos
- [ ] **Nunca logue senhas/tokens**: Sanitize antes de logar
- [ ] **Log de auditoria**: Para ações críticas (delete, pagamento, mudança de permissão)
- [ ] **Nível apropriado**: DEBUG local, INFO produção, ERROR para falhas
- [ ] **PII awareness**: Dados pessoais devem ser mascarados ou ter retenção limitada

### Exemplo: CORRETO ✅

```rust
use tracing::{info, warn, error};

async fn process_payment(
    user_id: UserId,
    amount: Money,
    card_number: &str,
) -> Result<PaymentId, AppError> {
    let correlation_id = generate_correlation_id();

    // ✅ Log estruturado sem dados sensíveis
    info!(
        correlation_id = %correlation_id,
        user_id = %user_id,
        amount = %amount,
        // ❌ NUNCA: card_number = %card_number
        card_last4 = %&card_number[card_number.len()-4..], // ✅ Apenas últimos 4 dígitos
        "Processing payment"
    );

    match payment_gateway.charge(card_number, amount).await {
        Ok(payment_id) => {
            // ✅ Log de auditoria
            info!(
                correlation_id = %correlation_id,
                payment_id = %payment_id,
                user_id = %user_id,
                amount = %amount,
                "Payment successful"
            );
            Ok(payment_id)
        }
        Err(e) => {
            // ✅ Log de erro sem expor detalhes ao usuário
            error!(
                correlation_id = %correlation_id,
                error = %e,
                "Payment failed"
            );
            Err(AppError::PaymentFailed) // ✅ Erro opaco
        }
    }
}
```

> **Leitura relacionada:** [observabilidade-producao.md](observabilidade-producao.md) — Logs, métricas e traces

---

## 🧪 Testes e Validação

### Checklist Obrigatório

- [ ] **Testes de boundary**: Valores mínimos, máximos, zero, negativos
- [ ] **Testes de injeção**: SQL injection, path traversal, XSS
- [ ] **Testes de autorização**: Usuário A não pode acessar dados de B
- [ ] **Testes de concorrência**: Simule requisições simultâneas
- [ ] **Testes de DoS**: Payloads grandes, loops infinitos
- [ ] **Fuzzing**: Para parsers e validadores

### Exemplo: Testes de Boundary

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_quantity_validation() {
        // ✅ Testa limites
        assert!(set_quantity(0).is_err());      // Zero
        assert!(set_quantity(-1).is_err());     // Negativo
        assert!(set_quantity(1).is_ok());       // Mínimo válido
        assert!(set_quantity(10000).is_ok());   // Máximo válido
        assert!(set_quantity(10001).is_err());  // Acima do máximo
        assert!(set_quantity(i32::MAX).is_err()); // Overflow
    }

    #[test]
    fn test_path_traversal() {
        // ✅ Testa ataques conhecidos
        assert!(serve_file("../etc/passwd").is_err());
        assert!(serve_file("../../etc/passwd").is_err());
        assert!(serve_file("/etc/passwd").is_err());
        assert!(serve_file("index.html").is_ok());
    }
}
```

---

## 📚 Resumo: Hierarquia de Defesa

### 1. Type System (Primeira Linha)

Use o compilador para eliminar classes inteiras de bugs:

- NewTypes (`Email`, `UserId`) impedem uso incorreto
- `Result<T, E>` força handling de erros
- Ownership previne data races

### 2. Validação de Input (Segunda Linha)

Todo dado externo é veneno até prova em contrário:

- Valide tipo, formato, tamanho
- Rejeite early no edge da aplicação
- Use whitelist, não blacklist

### 3. Isolamento de Recursos (Terceira Linha)

Minimize privilégios e blast radius:

- Prepared statements (DB)
- Sandboxing (filesystem)
- Rate limiting (network)

### 4. Observabilidade (Detecção)

Você não pode proteger o que não consegue ver:

- Logs estruturados
- Métricas de anomalia
- Alertas automáticos

### 5. Falha Segura (Última Linha)

Quando tudo falha, falhe de forma controlada:

- Erros opacos
- Circuit breakers
- Graceful degradation

---

## 🎯 Como Treinar o Checklist Mental

### 1. Code Review Próprio

Antes de cada commit:

- Releia o código e aplique os checklists relevantes
- Se encontrar violação, corrija imediatamente

### 2. Threat Modeling

Para cada função:

- "Se eu fosse um atacante, como abusaria disso?"
- "Qual o pior input possível?"
- "O que acontece sob concorrência?"

### 3. Estudo de Incidentes

Leia post-mortems de falhas de segurança:

- CVE database
- Blog posts de empresas sobre incidentes
- Relate com seus próprios checklists

### 4. Prática Deliberada

Implemente parsers, validadores e APIs:

- Sem frameworks (entenda o "porquê")
- Com testes de segurança desde o início
- Até o checklist se tornar instintivo

---

## 📖 Referências

- [logica-negocio.md](logica-negocio.md) — Vulnerabilidades lógicas (IDOR, DoS, timing)
- [toc-tou.md](toc-tou.md) — Race conditions e atomicidade
- [observabilidade-producao.md](observabilidade-producao.md) — Logs e métricas
- [distroless.md](distroless.md) — Minimalismo e redução de superfície de ataque
- [sandbox_rust_docker.md](sandbox_rust_docker.md) — Isolamento em containers

---

## Conclusão

Segurança não é uma fase do projeto. É uma **disciplina de escrita de código**.

O engenheiro sênior não precisa de um checklist externo — o checklist **é o processo de pensamento**. Cada função escrita passa por essa análise mental automaticamente.

Quando o checklist se torna instintivo, o código flui limpo, performático e, acima de tudo, **soberano**.
