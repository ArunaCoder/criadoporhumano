# 5.5 Observabilidade para Produção

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

**Por que isso importa:** Escolhemos `FROM scratch` no deploy, eliminando shell e ferramentas de debug. Em produção, observabilidade não é opcional — é sua **única janela** para o sistema.

## Os 3 Pilares

1. **Logs** — O que aconteceu (eventos discretos)
2. **Métricas** — Quanto e quando (agregações numéricas)
3. **Traces** — O caminho da requisição (rastreamento distribuído)

> **Para um guia completo de observabilidade em ambientes Distroless/FROM scratch, consulte:** [`../../security/observabilidade-producao.md`](../../security/observabilidade-producao.md)

---

## Logs Estruturados (Std Lib Only)

**Problema:** Logs de texto livre (`println!`) são impossíveis de query e correlacionar.

**Solução:** Logs em JSON para stdout.

```rust
use std::time::{SystemTime, UNIX_EPOCH};

fn log_request(method: &str, path: &str, status: u16, duration_ms: u64) {
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();

    // JSON manual (sem dependências)
    eprintln!(
        r#"{{"timestamp":{},"level":"info","method":"{}","path":"{}","status":{},"duration_ms":{}}}"#,
        timestamp, method, path, status, duration_ms
    );
}

// No handle_connection:
let start = std::time::Instant::now();
// ... processar request
log_request("GET", "/api/cpf", 200, start.elapsed().as_millis() as u64);
```

**Benefícios:**

- Logs são **queryables** por ferramentas como `jq`, Loki, ou CloudWatch
- Fácil filtrar por path, status, ou duração
- Sem dependências externas

---

## Correlation IDs

Para rastrear uma requisição através de múltiplos logs:

```rust
use std::sync::atomic::{AtomicU64, Ordering};

static REQUEST_ID_COUNTER: AtomicU64 = AtomicU64::new(0);

fn generate_request_id() -> u64 {
    REQUEST_ID_COUNTER.fetch_add(1, Ordering::Relaxed)
}

// No handle_connection:
let req_id = generate_request_id();

// Todos os logs incluem req_id:
eprintln!(
    r#"{{"timestamp":{},"request_id":{},"message":"Request started"}}"#,
    timestamp, req_id
);
```

**Ganho:** Todos os logs de uma requisição compartilham o mesmo ID.

---

## Métricas Básicas (Sem Prometheus)

Para MVP, você pode expor métricas simples via endpoint `/metrics`:

```rust
use std::sync::atomic::{AtomicU64, Ordering};

static TOTAL_REQUESTS: AtomicU64 = AtomicU64::new(0);
static TOTAL_ERRORS: AtomicU64 = AtomicU64::new(0);

// No handle_connection:
TOTAL_REQUESTS.fetch_add(1, Ordering::Relaxed);

// Endpoint /metrics:
fn handle_metrics() -> String {
    format!(
        "# HELP http_requests_total Total HTTP requests\n\
         http_requests_total {}\n\
         # HELP http_errors_total Total HTTP errors\n\
         http_errors_total {}\n",
        TOTAL_REQUESTS.load(Ordering::Relaxed),
        TOTAL_ERRORS.load(Ordering::Relaxed)
    )
}
```

**Formato Prometheus:** O formato acima é compatível com scraping do Prometheus.

---

## Health Check Verbose

```rust
fn handle_health() -> String {
    let uptime = /* calcular uptime */;
    format!(
        r#"{{"status":"healthy","uptime_seconds":{},"total_requests":{}}}"#,
        uptime,
        TOTAL_REQUESTS.load(Ordering::Relaxed)
    )
}
```

---

## Trade-off: FROM scratch

**Custo:** Sem shell = impossível fazer `docker exec` para debug.

**Compensação:**

1. ✅ Logs estruturados em JSON para stdout (`docker logs -f`)
2. ✅ Endpoint `/health` com informações do sistema
3. ✅ Endpoint `/metrics` para monitoramento externo
4. ✅ Debug **local** completo antes de containerizar

**Para ambientes críticos:** Considere Alpine (~20MB) se precisar de ferramentas de debug em produção. O trade-off de +18MB pode valer a pena.
