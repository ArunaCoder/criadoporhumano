# Trade-offs: Dependências Externas vs Implementação Manual

## Contexto

Este documento registra uma discussão técnica crítica realizada durante o planejamento arquitetural do projeto. A tensão entre dois princípios emergiu:

1. **Filosofia do Validador CPF:** "Engenheiro, não gestor de bibliotecas" — implementação manual usando std lib para compreensão profunda dos fundamentos.
2. **Pragmatismo SaaS:** Utilizar soluções maduras, battle-tested, para acelerar time-to-market e reduzir superfície de ataque.

Reconhecemos que **ambas as abordagens têm mérito**, mas em contextos diferentes. Este documento analisa **cada dependência crítica** sob três lentes:

- **A. Aprendizado:** O que você ganha implementando manualmente?
- **B. Migração:** Quão fácil é começar manual e migrar depois?
- **C. Maturidade:** Quais os desafios reais de depender da solução robusta?

---

## Framework HTTP: Axum/Actix-web vs std::net

### Stack Proposta no geral.md

- **Axum** (Tokio-based, typed routing)
- **Actix-web** (actor-based, alta performance)

### A. Aprendizado na Implementação Manual

**O que você aprende:**

- Protocolo HTTP linha por linha (request line, headers, body)
- TCP: socket lifecycle, accept loop, timeouts
- Parsing: state machines, buffer management, error recovery
- Segurança: DoS mitigation (timeouts, size limits), path traversal, method whitelist
- I/O models: blocking vs non-blocking, epoll/kqueue
- Performance: syscall overhead, zero-copy I/O

**Complexidade real:**

- **Básico (GET simples):** 200-300 linhas (factível em 1-2 dias)
- **Production-ready (POST + segurança):** 1000-1500 linhas (1 semana)
- **HTTP/1.1 completo:** 5000+ linhas (1 mês+)

**Limitações de implementação manual std::net:**

- Sem chunked transfer encoding
- Sem HTTP pipelining
- Sem HTTP/2 ou HTTP/3
- Parsing lento comparado a parsers otimizados (httparse usa SIMD)
- Vulnerabilidades sutis (slow loris, request smuggling)

**Valor pedagógico:** ⭐⭐⭐⭐⭐
Entender HTTP é **fundamental** para qualquer engenheiro backend. Você não pode debugar problemas de rede sem esse conhecimento.

### B. Facilidade de Migração

**Manual → Axum:** ⭐⭐⭐⭐ (fácil)

```rust
// Antes (manual)
fn handle_request(req: HttpRequest) -> HttpResponse {
    match req.path.as_str() {
        "/api/validate" => validate_cpf(req),
        _ => HttpResponse::not_found()
    }
}

// Depois (Axum)
async fn validate_cpf_handler(
    Json(payload): Json<ValidateRequest>
) -> impl IntoResponse {
    // Lógica de negócio permanece igual
}
```

**Esforço de migração:** ~1-2 dias para portar rotas existentes.

**Armadilhas:**

- Axum é async (requer refatoração se seu código era síncrono)
- Extractors têm semântica própria (validação automática)
- Error handling muda (precisa implementar `IntoResponse`)

**Compatibilidade de código de negócio:** ⭐⭐⭐⭐⭐
A lógica pura (validação de CPF, biometria) **não muda**. Apenas a camada de transporte.

### C. Desafios da Solução Madura

**Axum (2021, Tokio Team):**

- ✅ Type-safe routing (erros em compile time)
- ✅ Extrator system (parsing automático de JSON, query params)
- ✅ Integração nativa com Tower (middleware ecosystem)
- ✅ Performance próxima de Actix (benchmarks: ~700k req/s)
- ⚠️ Requer Tokio (async runtime, +500KB)
- ⚠️ Curva de aprendizado de async/await
- ⚠️ Debugging assíncrono é mais complexo (stack traces menos claros)

**Actix-web (2018, mais maduro):**

- ✅ Performance líder (benchmarks: ~800k req/s)
- ✅ Ecosystem robusto (middlewares, WebSocket)
- ✅ Estável, usado em produção por milhares de empresas
- ⚠️ API mais verbosa
- ⚠️ Sistema de actors adiciona complexidade conceitual

**Tamanho do binário:**

- std::net manual: ~1-2MB
- Axum: ~3-5MB (+Tokio overhead)
- Actix-web: ~4-6MB

**Superfície de ataque:**

- Manual: apenas seu código (auditável em 1 dia)
- Axum: ~150 dependências transitivas (Tokio, hyper, tower, etc.)
- Actix: ~120 dependências transitivas

**Vulnerabilidades históricas:**

- Axum: 0 CVEs conhecidas (projeto novo)
- Actix: 2 CVEs menores (ambos corrigidos rapidamente)
- Manual: depende da sua auditoria (slow loris, request smuggling são fáceis de implementar incorretamente)

### Veredito

**Para MVP educacional (validador CPF):** Implementação manual ⭐⭐⭐⭐⭐
Valor pedagógico supera o overhead.

**Para SaaS production (Criado por Humano):** Axum ⭐⭐⭐⭐⭐

- Async é necessário para suportar milhares de conexões simultâneas
- Type-safe routing reduz bugs em produção
- Migração é fácil (lógica de negócio separada)

**Estratégia recomendada:**

1. **Fase 1:** Implementar validador com std::net (aprender)
2. **Fase 2:** Migrar para Axum antes de adicionar features complexas (autenticação, WebSocket)
3. **Justificativa:** Você terá o conhecimento profundo de HTTP, mas não pagará o custo de manter parser manual em produção.

---

## Banco de Dados: PostgreSQL vs SQLite vs Manual (JSON files)

### Stack Proposta no geral.md

- **PostgreSQL** para usuários e metadados
- **Redis** para cache

### A. Aprendizado na Implementação Manual

**Opção 1: JSON files no filesystem**

```rust
// Serializar struct para JSON
let user = User { id: 1, name: "João" };
std::fs::write("users/1.json", serde_json::to_string(&user)?)?;
```

**O que você aprende:**

- Serialization (JSON, binário)
- Filesystem I/O (atômico? `write` + `rename` para evitar corrupção)
- Concorrência: file locking (`flock`) ou race conditions
- Indexação manual (HashMap em memória)

**Limitações críticas:**

- ❌ Sem transactions (operação multi-file = inconsistência)
- ❌ Sem queries complexas (JOIN manual)
- ❌ Sem índices (scan completo = O(n))
- ❌ Sem integridade referencial (foreign keys)
- ❌ Corrupto se processo crashar durante write

**Viável para:** Configurações, caches, logs.
**Inviável para:** Dados transacionais, múltiplos usuários.

**Opção 2: SQLite (embedded SQL)**

```rust
let conn = rusqlite::Connection::open("app.db")?;
conn.execute("INSERT INTO users (name) VALUES (?)", ["João"])?;
```

**O que você aprende:**

- SQL (DDL, DML, queries)
- Transactions (ACID)
- Índices (B-tree)
- Migrations (schema evolution)

**Limitações vs PostgreSQL:**

- ✅ Embedded (zero setup, arquivo único)
- ✅ Transactional (ACID completo)
- ⚠️ Sem concorrência de escrita (1 writer por vez, lock de arquivo)
- ⚠️ Performance degrada com >100GB de dados
- ⚠️ Sem replicação nativa (primary-replica)
- ⚠️ Sem full-text search avançado

**Valor pedagógico:**

- JSON files: ⭐⭐ (entende filesystem, mas limitado)
- SQLite: ⭐⭐⭐⭐ (aprende SQL sem overhead de server)

### B. Facilidade de Migração

**JSON → SQLite:** ⭐⭐⭐ (médio)

- Precisa criar schema SQL
- Migração de dados via script (parsear JSON, inserir)
- Queries mudam completamente

**SQLite → PostgreSQL:** ⭐⭐⭐⭐⭐ (fácil)

- SQL é 95% compatível
- ORM (Diesel, SQLx) abstrai diferenças
- Ferramentas de migração: `pgloader`, scripts

```rust
// Com SQLx, apenas muda connection string
// SQLite
let pool = SqlitePool::connect("sqlite:app.db").await?;

// PostgreSQL (código idêntico)
let pool = PgPool::connect("postgres_escapa_gitleaks://localhost/app").await?;
sqlx::query!("SELECT * FROM users").fetch_all(&pool).await?;
```

**Armadilhas:**

- PostgreSQL tem tipos mais ricos (ARRAY, JSONB, UUID)
- Diferenças em functions (DATE, RANDOM vs RAND)
- Performance tuning é diferente (indexes, vacuum, pg_stat)

### C. Desafios da Solução Madura

**SQLite:**

- ✅ Zero ops (backup = copiar arquivo)
- ✅ Transacional (ACID)
- ✅ Rápido para leitura (benchmarks: ~100k SELECT/s)
- ✅ Perfeito para embedded apps, mobile, edge
- ⚠️ 1 escritor por vez (bottleneck se muitas writes)
- ⚠️ Sem HA nativa (single point of failure)

**PostgreSQL:**

- ✅ Concorrência de escrita (MVCC)
- ✅ Replicação (primary-replica, logical)
- ✅ Full-text search (tsvector, GIN indexes)
- ✅ Extensões (PostGIS, pgcrypto)
- ✅ JSON/JSONB nativo (queries complexas)
- ⚠️ Requer servidor separado (ops overhead)
- ⚠️ Backups mais complexos (pg_dump, WAL archiving)
- ⚠️ Tuning necessário (shared_buffers, work_mem)

**Tamanho/Complexidade:**

- JSON files: 0 deps (apenas std::fs)
- SQLite: 1 dep (`rusqlite`), ~500KB no binário
- PostgreSQL: client lib (~200KB) + server separado (não afeta binário)

**Quando cada um é adequado:**

| Cenário                            | Solução    | Justificativa           |
| ---------------------------------- | ---------- | ----------------------- |
| Config files, feature flags        | JSON files | Simples, humano-legível |
| App desktop, mobile, CLI           | SQLite     | Embedded, zero setup    |
| SaaS <1000 usuários, single server | SQLite     | Suficiente, menos ops   |
| SaaS >10k usuários, HA necessária  | PostgreSQL | Escala, replicação      |

### Veredito

**Para validador CPF:** SQLite ⭐⭐⭐⭐⭐
Zero overhead operacional, aprende SQL de verdade.

**Para SaaS MVP (<5k usuários):** SQLite ⭐⭐⭐⭐⭐
Não pague o custo de PostgreSQL até **provar** que precisa.

**Para SaaS maduro (>10k usuários):** PostgreSQL ⭐⭐⭐⭐⭐
Migração de SQLite é trivial quando chegar o momento.

**Estratégia recomendada:**

1. **Fase 1-2:** SQLite (aprende SQL, zero ops)
2. **Fase 3:** Migrar para PostgreSQL quando métricas mostrarem gargalo de concorrência ou necessidade de HA
3. **Red flag para migração:** >100 writes/segundo com latência >50ms

---

## Cache: Redis vs Manual (HashMap)

### Stack Proposta no geral.md

- **Redis** para cache de análise em tempo real

### A. Aprendizado na Implementação Manual

**Opção: HashMap em memória**

```rust
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

struct Cache {
    data: Arc<RwLock<HashMap<String, String>>>
}

impl Cache {
    fn get(&self, key: &str) -> Option<String> {
        self.data.read().unwrap().get(key).cloned()
    }

    fn set(&self, key: String, val: String) {
        self.data.write().unwrap().insert(key, val);
    }
}
```

**O que você aprende:**

- Concurrency primitives (RwLock, Arc)
- Memory management (quando liberar?)
- Eviction policies (LRU, LFU, TTL)
- Thread safety (race conditions)

**Implementar LRU cache completo:**

```rust
// Precisa de doubly-linked list + HashMap
// ~300-500 linhas de unsafe code
// Lida com lifetimes complexos
```

**Limitações:**

- ❌ Memória não compartilhada entre processos
- ❌ Perde tudo em restart
- ❌ Sem TTL automático (precisa de background thread)
- ❌ Sem persistência

**Valor pedagógico:** ⭐⭐⭐⭐
Implementar LRU cache é exercício clássico de estruturas de dados.

### B. Facilidade de Migração

**HashMap → Redis:** ⭐⭐⭐⭐⭐ (muito fácil)

```rust
// Antes (HashMap)
cache.set("user:123", user_json);
let val = cache.get("user:123");

// Depois (Redis)
redis.set("user:123", user_json).await?;
let val: String = redis.get("user:123").await?;
```

**Interface é praticamente idêntica.** Única mudança: `async`.

### C. Desafios da Solução Madura

**HashMap in-memory:**

- ✅ Latência ínfima (<1µs)
- ✅ Zero deps
- ✅ Type-safe (Rust garante)
- ⚠️ Não persiste (volatil)
- ⚠️ Não escala horizontalmente
- ⚠️ Memória limitada pelo processo

**Redis:**

- ✅ Persistência opcional (RDB snapshots, AOF log)
- ✅ Estruturas avançadas (Sets, Sorted Sets, HyperLogLog)
- ✅ Pub/Sub (broadcast de eventos)
- ✅ Cluster mode (sharding automático)
- ✅ TTL automático (expiry)
- ⚠️ Latência de rede (~0.5-2ms local)
- ⚠️ Requer servidor separado (ops overhead)
- ⚠️ Single-threaded (bottleneck em CPU-bound workloads)

**Alternativas modernas:**

- **Valkey:** Fork open-source do Redis (pós-licença)
- **DragonflyDB:** Drop-in replacement multi-threaded (25x faster)
- **KeyDB:** Fork multi-threaded do Redis

**Quando você precisa de Redis?**

- Múltiplos processos/servidores precisam compartilhar cache
- Precisa de TTL automático
- Precisa de pub/sub
- Cache sobrevive a restarts

### Veredito

**Para validador CPF (single process):** HashMap ⭐⭐⭐⭐⭐
Latência 100x menor, suficiente.

**Para SaaS MVP (1 servidor):** HashMap ⭐⭐⭐⭐
Adicionar Redis quando escalar para múltiplos processos.

**Para SaaS distribuído:** Redis/Valkey ⭐⭐⭐⭐⭐
Necessário para coordenação entre servidores.

**Estratégia recomendada:**

1. Começar com HashMap (ou crate `moka`, `mini-moka`)
2. Migrar para Redis apenas quando deploy multi-servidor
3. Interface de cache abstrata desde o início:

```rust
trait Cache {
    async fn get(&self, key: &str) -> Option<String>;
    async fn set(&self, key: &str, val: &str);
}
// Implementações: MemoryCache, RedisCache
```

---

## Email: SendGrid/AWS SES vs SMTP Manual

### Stack Proposta no geral.md

- **SendGrid**, **AWS SES**, ou **Resend**

### A. Aprendizado na Implementação Manual

**SMTP direto (std lib):**

```rust
use std::net::TcpStream;
use std::io::{Write, BufRead, BufReader};

fn send_email(to: &str, subject: &str, body: &str) -> Result<()> {
    let mut stream = TcpStream::connect("smtp.gmail.com:587")?;
    // EHLO, STARTTLS, AUTH LOGIN, MAIL FROM, RCPT TO, DATA
    // ~200 linhas de parsing SMTP protocol
}
```

**O que você aprende:**

- Protocolo SMTP (RFC 5321)
- TLS handshake (STARTTLS)
- Base64 encoding (AUTH LOGIN)
- MIME multipart (anexos, HTML + plaintext)
- DNS: MX records, SPF, DKIM, DMARC

**Complexidade real:**

- **SMTP básico (texto puro):** ~200-300 linhas
- **Com TLS:** +500 linhas (ou dep: `native-tls`)
- **HTML + attachments:** +300 linhas (MIME encoding)
- **DKIM signing:** +1000 linhas (crypto)

**Limitações críticas:**

- ❌ Gmail/Outlook bloqueiam IPs de VPS (reputação)
- ❌ Sem SPF/DKIM/DMARC = spam folder
- ❌ Rate limits rigorosos (25 emails/dia no Gmail)
- ❌ Sem analytics (bounces, opens, clicks)
- ❌ Listas de blacklist (Spamhaus, etc.)

**Valor pedagógico:** ⭐⭐⭐
Entender SMTP é útil, mas setup de email deliverability é **engenharia de infraestrutura**, não software.

### B. Facilidade de Migração

**SMTP manual → SendGrid:** ⭐⭐⭐⭐⭐ (trivial)

```rust
// Antes (SMTP)
send_email("user@example.com", "Welcome", "Hello");

// Depois (SendGrid API)
let client = SendgridClient::new(api_key);
client.send(Email {
    to: "user@example.com",
    subject: "Welcome",
    html: "<p>Hello</p>"
}).await?;
```

### C. Desafios da Solução Madura

**SMTP direto:**

- ✅ Zero custo (até rate limit)
- ✅ Controle total
- ⚠️ Deliverability péssimo (99% cai em spam)
- ⚠️ Precisa gerenciar reputação de IP (warmup de meses)
- ⚠️ Blacklists (uma reclamação = IP bloqueado)
- ⚠️ Sem analytics

**SendGrid:**

- ✅ Deliverability 95%+ (IP warming gerenciado)
- ✅ Analytics (opens, clicks, bounces)
- ✅ Templates (emails transacionais)
- ✅ Webhooks (eventos em tempo real)
- ✅ DKIM/SPF configurado automaticamente
- ⚠️ Custo: $15/mês (10k emails), $80/mês (100k)
- ⚠️ Vendor lock-in (templates proprietários)

**AWS SES:**

- ✅ Mais barato: $0.10 por 1000 emails
- ✅ Integração com AWS (SNS, Lambda)
- ⚠️ Sandbox inicial (precisa solicitar production access)
- ⚠️ Menos analytics que SendGrid
- ⚠️ API mais verbosa

**Resend (2023):**

- ✅ API moderna (DX focado)
- ✅ React Email integration
- ✅ Pricing justo ($20/mês para 50k emails)
- ⚠️ Empresa nova (menos track record)

### Veredito

**Para validador CPF (emails raros):** SMTP manual ou `lettre` crate ⭐⭐⭐
Suficiente para reset de senha ocasional.

**Para SaaS (emails transacionais críticos):** SendGrid/Resend ⭐⭐⭐⭐⭐
Deliverability não é negociável. Cliente não receber email de confirmação = churn.

**Estratégia recomendada:**

1. **MVP:** Usar SendGrid desde o início (free tier: 100 emails/dia)
2. **Motivo:** Email deliverability leva meses para construir (reputação de IP)
3. **Abstração:** Criar trait `EmailProvider` para trocar backend depois

```rust
trait EmailProvider {
    async fn send(&self, email: Email) -> Result<()>;
}
// Implementações: SendGridProvider, SESProvider, SMTPProvider (dev)
```

**Exceção:** Se você tem domínio antigo com reputação estabelecida + time de DevOps para gerenciar Postfix, SMTP direto é viável.

---

## Pagamentos: Stripe/Mercado Pago vs Manual

### Stack Proposta no geral.md

- **Stripe** ou **Mercado Pago**

### A. Aprendizado na Implementação Manual

**Teoricamente possível:**

- Integrar com gateway de pagamento via HTTP API
- Processar webhooks de confirmação
- Gerenciar estados de transação (pending, paid, refunded)

**Na prática:**

```rust
// Você precisaria implementar:
// - PCI-DSS compliance (nunca tocar dados de cartão)
// - Criptografia end-to-end
// - Detecção de fraude
// - Chargebacks
// - Compliance bancário (regulação financeira)
```

**Complexidade:** ⭐⭐⭐⭐⭐ (insano)
**Valor pedagógico:** ⭐ (não aprende nada útil, apenas regulação)

### B. Facilidade de Migração

**N/A** — você nunca implementaria isso manualmente.

### C. Desafios da Solução Madura

**Stripe:**

- ✅ PCI-DSS compliant (liability shift)
- ✅ API excelente (webhooks, idempotency)
- ✅ Suporta 135+ moedas
- ✅ Checkout.js (frontend pronto)
- ✅ Billing (subscriptions, invoices)
- ⚠️ 2.9% + $0.30 por transação (caro)
- ⚠️ Precisa de empresa no exterior (ou Stripe Brasil, limitado)

**Mercado Pago (América Latina):**

- ✅ Pix (instantâneo, sem taxa)
- ✅ Boleto bancário
- ✅ Parcelamento sem juros (incentivo cultural)
- ✅ Integração com Mercado Livre
- ⚠️ 4.99% + R$0.39 por transação (mais caro que Stripe)
- ⚠️ API menos polida
- ⚠️ Documentação inconsistente

**Alternativas:**

- **PagSeguro:** Similar ao Mercado Pago
- **Asaas:** Focado em SaaS brasileiro (cobranças recorrentes)

### Veredito

**Nunca implemente pagamentos manualmente.** ⚠️⚠️⚠️

**Para SaaS Brasil:** Mercado Pago ⭐⭐⭐⭐⭐
Pix é obrigatório (expectativa do mercado).

**Para SaaS global:** Stripe ⭐⭐⭐⭐⭐
Padrão da indústria.

**Estratégia recomendada:**

1. Começar com Mercado Pago (Pix + Boleto)
2. Adicionar Stripe se internacionalizar
3. Usar abstração desde o início:

```rust
trait PaymentProvider {
    async fn create_checkout(&self, amount: i64) -> Result<CheckoutUrl>;
    async fn verify_webhook(&self, payload: &[u8]) -> Result<Event>;
}
```

---

## Editor Frontend: Lexical vs Manual

### Stack Proposta no geral.md

- **Lexical** (Meta, sucessor do Draft.js)

### A. Aprendizado na Implementação Manual

**Editor básico:**

```html
<div contenteditable="true"></div>
```

**O que você aprende:**

- DOM manipulation
- Selection API (caret position)
- Keyboard events (Ctrl+B para bold)
- ClipboardEvent (paste com formatação)
- Undo/Redo stack

**Complexidade de editor production-ready:**

- **Plain text com Ctrl+Z:** ~500 linhas
- **Rich text (bold, italic):** ~2000 linhas
- **Blocos (headers, listas):** ~5000 linhas
- **Colaboração real-time:** +10,000 linhas (OT ou CRDT)

**Problemas sutis:**

- Safari vs Chrome (behavior inconsistente)
- IME (teclado japonês, chinês)
- Acessibilidade (screen readers)
- Performance (documentos grandes)

**Valor pedagógico:** ⭐⭐⭐⭐
Entender DOM e eventos é fundamental, mas editor completo é rabbit hole infinito.

### B. Facilidade de Migração

**ContentEditable → Lexical:** ⭐⭐ (difícil)

Editores têm arquitetura completamente diferente:

- Manual: DOM é source of truth
- Lexical: Estado interno (EditorState) → render DOM

Migração = reescrita completa do editor.

### C. Desafios da Solução Madura

**Lexical:**

- ✅ React integration (ou vanilla)
- ✅ Plugin system (rich extensibility)
- ✅ Collision-resistant (múltiplos plugins não conflitam)
- ✅ Performance (virtual DOM interno)
- ✅ Acessibilidade (ARIA completo)
- ⚠️ ~100KB minified
- ⚠️ Curva de aprendizado (API única)
- ⚠️ Ecossistema ainda crescendo (lançado 2022)

**Alternativas:**

- **ProseMirror:** Mais maduro, usado por Notion, Atlassian
- **Slate:** React-based, mais customizável
- **Quill:** Simples, mas menos extensível
- **TipTap:** ProseMirror wrapper com API moderna

**Para captura biométrica:**
Você precisa de hooks baixo nível (keydown, keyup timing). Todos os editores modernos expõem isso via plugins.

### Veredito

**Para validador CPF:** N/A (não precisa de editor)

**Para SaaS (captura biométrica):** Lexical ou ProseMirror ⭐⭐⭐⭐⭐

**Motivo:** Você vai gastar 80% do dev time no algoritmo de detecção biométrica, não no editor. Use ferramenta pronta.

**Estratégia recomendada:**

1. Prototipar com `<textarea>` + keydown listeners (validar conceito biométrico)
2. Migrar para Lexical quando algoritmo estiver validado
3. Focar energia no core IP (análise biométrica), não em UI

---

## Autenticação: JWT Manual vs Crates

### Stack Proposta no geral.md

- **JWT** (JSON Web Tokens)

### A. Aprendizado na Implementação Manual

**JWT structure:**

```
header.payload.signature
eyJ0eXAiOiJKV1Q...  (Base64Url encoded)
```

**Implementação básica:**

```rust
// 1. Header (algorithm)
let header = r#"{"alg":"HS256","typ":"JWT"}"#;
let header_b64 = base64_url_encode(header);

// 2. Payload (claims)
let payload = r#"{"sub":"123","exp":1234567890}"#;
let payload_b64 = base64_url_encode(payload);

// 3. Signature (HMAC-SHA256)
let message = format!("{}.{}", header_b64, payload_b64);
let signature = hmac_sha256(secret_key, message);
let signature_b64 = base64_url_encode(signature);

// Token final
format!("{}.{}.{}", header_b64, payload_b64, signature_b64)
```

**O que você aprende:**

- Base64 encoding (URL-safe variant)
- HMAC (keyed-hash message authentication)
- Claims standard (iss, sub, exp, iat, nbf)
- Stateless authentication

**Complexidade:**

- **HS256 (HMAC):** ~100 linhas
- **RS256 (RSA):** ~500 linhas (ou dep: `rsa`, `sha2`)
- **Validação completa:** +200 linhas (expiry, issuer, audience)

**Armadilhas de segurança:**

- ❌ Timing attacks (comparação de signature deve ser constant-time)
- ❌ Algorithm confusion (`alg: none` vulnerability)
- ❌ Key management (rotação, revogação)

**Valor pedagógico:** ⭐⭐⭐⭐
Entender JWT é essencial (stateless auth é padrão).

### B. Facilidade de Migração

**Manual → `jsonwebtoken` crate:** ⭐⭐⭐⭐⭐

```rust
// Antes (manual)
let token = create_jwt(user_id, secret);

// Depois (jsonwebtoken)
use jsonwebtoken::{encode, Header, EncodingKey};
let token = encode(
    &Header::default(),
    &claims,
    &EncodingKey::from_secret(secret)
)?;
```

### C. Desafios da Solução Madura

**Manual:**

- ✅ Entende o protocolo
- ✅ ~100 linhas
- ⚠️ Fácil cometer erro de segurança (timing attack)
- ⚠️ Só suporta HS256 (sem RSA)

**`jsonwebtoken` crate:**

- ✅ Auditado (security review)
- ✅ Constant-time comparison
- ✅ Suporte completo (HS256, RS256, ES256, PS256)
- ✅ Validação de claims automática
- ✅ ~50KB no binário
- ⚠️ API pode mudar (ainda pre-1.0)

**Alternativas:**

- **`jwt-simple`:** API mais simples
- **`biscuit`:** JWE (encrypted JWT)

### Veredito

**Para aprendizado:** Implementar HS256 manualmente ⭐⭐⭐⭐
Exercício valioso (1-2 dias).

**Para produção:** `jsonwebtoken` crate ⭐⭐⭐⭐⭐
Segurança não é lugar para erros.

**Estratégia recomendada:**

1. Implementar JWT básico manualmente (aprender)
2. Migrar para `jsonwebtoken` antes de produção
3. Focar energia em **gestão de refresh tokens** (revogação, rotação) — isso sim é complexo

---

## Monitoramento: Grafana+Prometheus vs Logs

### Stack Proposta no geral.md

- **Grafana** + **Prometheus** (métricas)
- **Sentry** (error tracking)

### A. Aprendizado na Implementação Manual

**Logging básico:**

```rust
println!("[INFO] Request received: GET /api/validate");
```

**Structured logging:**

```rust
eprintln!(
    r#"{{"level":"info","ts":{},"msg":"request","method":"GET"}}"#,
    timestamp()
);
```

**O que você aprende:**

- Log levels (DEBUG, INFO, WARN, ERROR)
- Structured data (JSON)
- Agregação (grep, awk, jq)
- Retention policies

**Limitações:**

- ❌ Sem dashboards visuais
- ❌ Sem alertas automáticos
- ❌ Sem correlação de eventos
- ❌ Difícil de escalar (GB de logs/dia)

**Métricas com contador manual:**

```rust
static REQUEST_COUNT: AtomicU64 = AtomicU64::new(0);

fn handle_request() {
    REQUEST_COUNT.fetch_add(1, Ordering::Relaxed);
}

// Expor em /metrics
format!("http_requests_total {}", REQUEST_COUNT.load(Ordering::Relaxed))
```

**Valor pedagógico:** ⭐⭐⭐
Entender métricas é importante, mas tooling é commodity.

### B. Facilidade de Migração

**Logs → Structured logs → Prometheus:** ⭐⭐⭐⭐

```rust
// 1. Adicionar crate `prometheus`
use prometheus::{Counter, register_counter};

let counter = register_counter!("requests_total", "Total requests").unwrap();

fn handle_request() {
    counter.inc();
}
```

Prometheus scrape `/metrics` endpoint automaticamente.

### C. Desafios da Solução Madura

**Logs simples (stdout):**

- ✅ Zero deps
- ✅ Funciona sempre
- ⚠️ Difícil de query
- ⚠️ Sem alertas

**Prometheus + Grafana:**

- ✅ Dashboards lindos (gráficos de série temporal)
- ✅ Alertas (Alertmanager)
- ✅ PromQL (query language poderosa)
- ⚠️ Requer 2 serviços adicionais (Prometheus + Grafana)
- ⚠️ Retention limitado (default: 15 dias)
- ⚠️ High cardinality problem (labels explode memória)

**Sentry (error tracking):**

- ✅ Stack traces automáticos
- ✅ Breadcrumbs (eventos antes do erro)
- ✅ Deduplicação de erros
- ✅ Alertas por email/Slack
- ⚠️ Custo: $26/mês (50k eventos)
- ⚠️ Envia dados para terceiro (privacy concern)

**Alternativas:**

- **GlitchTip:** Sentry open-source (self-hosted)
- **Loki:** Prometheus para logs (Grafana stack)

### Veredito

**Para MVP (<1000 usuários):** Structured logs ⭐⭐⭐⭐
`tail -f logs/app.log | jq` é suficiente.

**Para SaaS (>5000 usuários):** Prometheus ⭐⭐⭐⭐⭐
Observabilidade não é opcional em produção.

**Estratégia recomendada:**

1. **Fase 1:** Logs estruturados (crate `tracing`)
2. **Fase 2:** Adicionar `/metrics` endpoint quando deploy em produção
3. **Fase 3:** Prometheus + Grafana quando tiver usuários reais
4. **Sentry:** Adicionar desde MVP (free tier: 5k erros/mês) — previne surpresas

---

## Resumo Executivo: Classificação de Dependências

### ❌ Nunca Implementar Manualmente

| Dep              | Motivo                                               |
| ---------------- | ---------------------------------------------------- |
| **Pagamentos**   | PCI-DSS compliance, fraude, regulação bancária       |
| **Criptografia** | Timing attacks, side channels — use `ring`, `rustls` |

### 🟡 Implementar para Aprender, Migrar para Produção

| Dep             | Aprendizado | Migração   | Produção       |
| --------------- | ----------- | ---------- | -------------- |
| **HTTP server** | ⭐⭐⭐⭐⭐  | ⭐⭐⭐⭐   | Axum           |
| **JWT**         | ⭐⭐⭐⭐    | ⭐⭐⭐⭐⭐ | `jsonwebtoken` |
| **LRU cache**   | ⭐⭐⭐⭐    | ⭐⭐⭐⭐⭐ | `moka`         |

### 🟢 Usar Solução Madura Desde o Início

| Dep                | Motivo                    | Recomendação        |
| ------------------ | ------------------------- | ------------------- |
| **Banco de dados** | SQL é complexo            | SQLite → PostgreSQL |
| **Email**          | Deliverability leva meses | SendGrid/Resend     |
| **Editor**         | Rabbit hole infinito      | Lexical/ProseMirror |
| **Observability**  | Commodity                 | Prometheus + Sentry |

### 🔵 Depende do Contexto

| Dep       | Single Server | Distribuído |
| --------- | ------------- | ----------- |
| **Cache** | HashMap       | Redis       |
| **Logs**  | stdout        | Loki        |

---

## Princípios Orientadores

### 1. Implemente Manualmente para Entender, Não para Produção

> "Você não entende algo até conseguir implementar do zero."

Mas: produção não é lugar para experimentos. Aprenda offline, use battle-tested online.

### 2. Migração Deve Ser Fácil

Arquitetura limpa = trocável:

```rust
trait HttpServer { /* ... */ }
trait Database { /* ... */ }
trait Cache { /* ... */ }

// Implementações: Manual, Axum, PostgreSQL, Redis
```

### 3. Dependências São Dívida Técnica

Cada dep é:

- Superfície de ataque (CVEs)
- Ponto de falha (breaking changes)
- Tempo de build (+30s por crate grande)

Mas: reinventar roda é dívida técnica pior (bugs, manutenção).

### 4. Contexto Importa

**Validador CPF (educacional):**

- Zero deps é feature (aprender tudo)

**SaaS (comercial):**

- Time-to-market > pureza arquitetural
- Use deps para commodities, implemente core IP

---

## Estratégia Proposta: 3 Fases

### Fase 1: Fundamentos (Validador CPF)

**Duração:** 2-3 semanas
**Objetivo:** Aprender profundamente

- [x] HTTP server manual (std::net)
- [x] JSON parsing manual
- [ ] JWT manual (HS256)
- [ ] SQLite (SQL real, ops simples)
- [ ] Structured logs (stdout)

**Resultado:** Conhecimento sólido de fundações.

### Fase 2: MVP SaaS (Criado por Humano)

**Duração:** 2-3 meses
**Objetivo:** Validar produto

- [ ] Migrar para Axum (async necessário para WebSocket biométrico)
- [ ] SQLite (suficiente para MVP)
- [ ] HashMap cache (single server)
- [ ] SendGrid (deliverability não-negociável)
- [ ] Lexical (editor pronto, foco em biometria)
- [ ] Mercado Pago (Pix é expectativa)
- [ ] Sentry free tier (prevenir surpresas)

**Resultado:** Produto funcional para primeiros 100 usuários.

### Fase 3: Scale (>10k usuários)

**Duração:** 6-12 meses (após product-market fit)
**Objetivo:** Escalar infra

- [ ] PostgreSQL (quando SQLite mostrar gargalo)
- [ ] Redis (quando deploy multi-servidor)
- [ ] Prometheus + Grafana (observabilidade completa)
- [ ] Kubernetes ou Fly.io (orquestração)

**Gatilho de migração:** Métricas concretas (latência p99 >100ms, downtime mensal >1h).

---

## Conclusão

Não existe resposta binária "deps sim vs não". A pergunta certa é:

> **"Esta dependência está no meu caminho crítico de aprendizado?"**

- **Sim:** Implemente manualmente (ex: HTTP server)
- **Não:** Use solução madura (ex: email deliverability)

**Validador CPF** é sandbox de aprendizado — maximize implementação manual.
**SaaS production** é produto comercial — minimize risco, maximize velocidade.

Sabendo **como** reimplementar qualquer dep te dá superpoder: você pode debugar, auditar e otimizar qualquer parte do stack quando necessário.

Mas também te ensina **quando não** reimplementar: pagamentos, criptografia, compliance — delegue para especialistas.

**Este documento é vivo:** revisite a cada milestone para reavaliar trade-offs.
