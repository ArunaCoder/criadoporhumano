# 🚀 Camada 5: Otimizações Avançadas (Fase 2 - Produção)

**Anterior:** [04-camada-deploy.md](04-camada-deploy.md)

---

## 5.0 Visão Geral

**Contexto:** Este documento cobre otimizações de **Fase 2** — implementações que exigem crates externas ou complexidade significativa. Só implemente após completar Camadas 1-4 e validar que o sistema funciona corretamente.

**Quando implementar:**

- ✅ MVP funcional e deployado
- ✅ Profiling mostra gargalos reais (não otimização prematura)
- ✅ Tráfego justifica otimização (>10k req/s ou latência p99 >100ms)

**Filosofia:** "Faça funcionar, faça certo, faça rápido" — nessa ordem.

---

## 5.1 Thread Pool (Paralelização Multi-Core)

### 💭 Pensamento do Engenheiro

**O problema:**

Implementação atual é **single-threaded**:

```rust
for stream in listener.incoming() {
    handle_connection(stream, config);  // Bloqueia até terminar
}
```

Apenas **1 CPU core** é usado. Em máquina com 8 cores, desperdiçamos **87.5% da capacidade**.

**Impacto:**

- 1 core: ~5k req/s
- 8 cores (com thread pool): ~40k req/s
- **Ganho: 8x throughput**

**Como funciona:**

Thread pool = fila de trabalho + N threads workers:

```
Requests chegando → Fila → Thread 1 processa
                         → Thread 2 processa
                         → Thread 3 processa
                         → Thread N processa
```

Cada worker pega próxima request da fila e processa independentemente.

**Implementação:**

### Opção A: Crate `rayon` (Recomendado)

```rust
use rayon::prelude::*;

fn start_server(addr: &str, config: &ServerConfig) -> std::io::Result<()> {
    let listener = TcpListener::bind(addr)?;

    // Rayon automaticamente cria thread pool
    listener.incoming()
        .par_bridge()  // Converte para parallel iterator
        .for_each(|stream| {
            match stream {
                Ok(s) => handle_connection(s, config),
                Err(e) => eprintln!("Connection error: {}", e),
            }
        });

    Ok(())
}
```

**Prós:**

- ✅ 5 linhas de código
- ✅ Work stealing automático (balanceamento de carga)
- ✅ Thread pool gerenciado (N = número de cores)

**Contras:**

- ❌ Adiciona ~500KB ao binário
- ❌ Menos controle sobre pool

### Opção B: Thread Pool Manual (Educacional)

```rust
use std::sync::{Arc, Mutex, mpsc};
use std::thread;

struct ThreadPool {
    workers: Vec<Worker>,
    sender: mpsc::Sender<Job>,
}

type Job = Box<dyn FnOnce() + Send + 'static>;

impl ThreadPool {
    fn new(size: usize) -> Self {
        let (sender, receiver) = mpsc::channel();
        let receiver = Arc::new(Mutex::new(receiver));

        let workers = (0..size)
            .map(|id| Worker::new(id, Arc::clone(&receiver)))
            .collect();

        ThreadPool { workers, sender }
    }

    fn execute<F>(&self, f: F)
    where
        F: FnOnce() + Send + 'static,
    {
        self.sender.send(Box::new(f)).unwrap();
    }
}

struct Worker {
    id: usize,
    thread: thread::JoinHandle<()>,
}

impl Worker {
    fn new(id: usize, receiver: Arc<Mutex<mpsc::Receiver<Job>>>) -> Self {
        let thread = thread::spawn(move || loop {
            let job = receiver.lock().unwrap().recv();

            match job {
                Ok(job) => {
                    println!("Worker {} executing job", id);
                    job();
                }
                Err(_) => break,
            }
        });

        Worker { id, thread }
    }
}

// Uso:
fn start_server(addr: &str, config: &ServerConfig) -> std::io::Result<()> {
    let listener = TcpListener::bind(addr)?;
    let pool = ThreadPool::new(num_cpus::get());  // Requer crate num_cpus
    let config = Arc::new(config);  // Compartilhar config entre threads

    for stream in listener.incoming() {
        let stream = stream?;
        let config_clone = Arc::clone(&config);

        pool.execute(move || {
            handle_connection(stream, &config_clone);
        });
    }

    Ok(())
}
```

**Prós:**

- ✅ Controle total sobre threads
- ✅ Valor educacional alto (entender concorrência)
- ✅ Zero abstrações mágicas

**Contras:**

- ❌ ~100 linhas de código
- ❌ Sem work stealing (desbalanceamento possível)
- ❌ Mais bugs potenciais (deadlocks, panics em threads)

### Trade-offs

**Quando usar thread pool:**

- ✅ CPU-bound: validação de CPF, criptografia, compressão
- ✅ Multi-core disponível (servidor production)
- ✅ Tráfego alto (>5k req/s)

**Quando NÃO usar:**

- ❌ I/O-bound: 99% do tempo esperando disco/network (use async)
- ❌ Single-core VPS (overhead > ganho)
- ❌ Tráfego baixo (<1k req/s)

### Checklist

- [ ] **DECISÃO:** Escolher Rayon (produtividade) ou manual (aprendizado)
- [ ] **CARGO.TOML:** Adicionar dependência:
  ```toml
  [dependencies]
  rayon = "1.7"  # Opção A
  # ou
  num_cpus = "1.15"  # Opção B (detectar número de cores)
  ```
- [ ] **REFATORAR:** Envolver `ServerConfig` em `Arc` para compartilhar entre threads:
  ```rust
  let config = Arc::new(ServerConfig::new(None)?);
  ```
- [ ] **IMPLEMENTAR:** Pool conforme opção escolhida (ver código acima)
- [ ] **TESTE:** Benchmark antes/depois com `wrk`:

  ```bash
  # Antes (single-threaded)
  wrk -t4 -c100 -d30s http://localhost:8080/health
  # Resultado: ~5k req/s

  # Depois (thread pool)
  wrk -t4 -c100 -d30s http://localhost:8080/health
  # Resultado esperado: ~20-40k req/s (depende de cores)
  ```

- [ ] **VALIDAÇÃO:** Confirmar que não há data races com `cargo test` + `cargo clippy`
- [ ] **MONITORAMENTO:** Verificar uso de CPU:
  ```bash
  top -p $(pgrep api)
  # Deve mostrar ~800% CPU em máquina 8-core (usa todos)
  ```

---

## 5.2 Zero-Copy File Serving (sendfile syscall)

### 💭 Pensamento do Engenheiro

**O problema:**

Atualmente, servir arquivo requer **2 cópias**:

```
Disco → Kernel buffer → User space (Vec<u8>) → Kernel buffer → Socket
        (cópia 1)       (cópia 2)
```

Isso desperdiça CPU e memória, especialmente para arquivos grandes.

**Solução: `sendfile()` syscall**

```
Disco → Kernel buffer → Socket
        (zero-copy kernel-level)
```

Kernel copia diretamente do disco para socket, sem passar por user space.

**Impacto:**

- Arquivo 1MB servido 1000 vezes/segundo
- Sem sendfile: 1000 × 1MB × 2 = **2GB/s de cópias desnecessárias**
- Com sendfile: **0 cópias em user space**
- **Ganho: 2-5x para arquivos grandes**

**Quando compensa:**

- ✅ Arquivos >100KB (imagens, PDFs, videos)
- ❌ Arquivos pequenos (<10KB) — overhead do syscall > ganho

### Implementação

```rust
use nix::sys::sendfile::sendfile;
use std::os::unix::io::AsRawFd;

fn serve_file_zero_copy(
    file_path: &Path,
    stream: &mut TcpStream,
) -> Result<(), String> {
    let file = fs::File::open(file_path)
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let metadata = file.metadata()
        .map_err(|e| format!("Failed to get metadata: {}", e))?;

    let file_size = metadata.len();

    // Decisão: usar sendfile() apenas para arquivos grandes
    const ZERO_COPY_THRESHOLD: u64 = 102_400; // 100KB

    if file_size < ZERO_COPY_THRESHOLD {
        // Arquivos pequenos: método tradicional (cache hit provável)
        let data = fs::read(file_path)?;
        stream.write_all(&data)?;
        return Ok(());
    }

    // Arquivos grandes: zero-copy
    unsafe {
        let file_fd = file.as_raw_fd();
        let socket_fd = stream.as_raw_fd();

        let mut offset = 0;
        let mut remaining = file_size;

        while remaining > 0 {
            match sendfile(socket_fd, file_fd, Some(&mut offset), remaining as usize) {
                Ok(sent) => {
                    remaining -= sent as u64;
                }
                Err(e) => return Err(format!("sendfile failed: {}", e)),
            }
        }
    }

    Ok(())
}
```

**Limitações:**

- ❌ **Linux-only:** sendfile() não existe no Windows (usar `TransmitFile`)
- ❌ **Unsafe code:** Trabalha com file descriptors crus
- ⚠️ **Não funciona com HTTPS:** SSL requer criptografia em user space

### Cross-platform

```rust
#[cfg(target_os = "linux")]
fn serve_file_optimized(path: &Path, stream: &mut TcpStream) -> Result<(), String> {
    serve_file_zero_copy(path, stream)
}

#[cfg(not(target_os = "linux"))]
fn serve_file_optimized(path: &Path, stream: &mut TcpStream) -> Result<(), String> {
    // Fallback: método tradicional
    let data = fs::read(path)?;
    stream.write_all(&data)?;
    Ok(())
}
```

### Checklist

- [ ] **CARGO.TOML:** Adicionar dependência:
  ```toml
  [dependencies]
  nix = { version = "0.27", features = ["fs"] }  # Linux only
  ```
- [ ] **IMPLEMENTAR:** Função `serve_file_zero_copy()` (ver código acima)
- [ ] **INTEGRAR:** Usar no routing para arquivos estáticos grandes:
  ```rust
  match req.path.extension().and_then(|e| e.to_str()) {
      Some("jpg") | Some("png") | Some("pdf") => {
          // Usar zero-copy para arquivos grandes
          serve_file_optimized(&path, &mut stream)?;
      }
      _ => {
          // Método tradicional + cache para HTML/CSS/JS
          let data = serve_static_file(&path, config)?;
          stream.write_all(&data)?;
      }
  }
  ```
- [ ] **TESTE:** Benchmark com arquivo grande:

  ```bash
  # Criar arquivo de teste
  dd if=/dev/urandom of=backend/api/public/large.bin bs=1M count=10  # 10MB

  # Benchmark antes (método tradicional)
  wrk -t4 -c10 -d30s http://localhost:8080/large.bin
  # Resultado: ~500 req/s

  # Benchmark depois (sendfile)
  wrk -t4 -c10 -d30s http://localhost:8080/large.bin
  # Resultado esperado: ~1200 req/s (2-3x melhora)
  ```

- [ ] **VALIDAÇÃO:** Confirmar que arquivos pequenos ainda usam cache:
  ```bash
  curl http://localhost:8080/index.html  # Deve usar cache (rápido)
  curl http://localhost:8080/large.bin   # Deve usar sendfile (eficiente)
  ```
- [ ] **MONITORAMENTO:** Verificar que não há cópias desnecessárias:
  ```bash
  strace -e sendfile ./target/release/api 2>&1 | grep sendfile
  # Deve mostrar chamadas sendfile() para arquivos grandes
  ```

---

## 5.3 Async/Await (Opcional - Requer Reescrita)

**⚠️ AVISO:** Esta é uma **reescrita arquitetural completa**. Só considere se:

- Tráfego >100k req/s
- I/O é gargalo (muito tempo esperando disco/network)
- Justifica abandonar std lib

### Trade-offs

**Async (Tokio/async-std):**

- ✅ Escala para milhões de conexões (1 thread gerencia 10k+ conexões)
- ✅ Ideal para I/O-bound (99% esperando, 1% processando)
- ❌ Complexidade: `async`/`.await`, lifetimes complexos, runtime overhead
- ❌ Binário +2MB (Tokio é pesado)
- ❌ Debug mais difícil (stack traces assíncronos)

**Sync threads (atual):**

- ✅ Simples, debugável, previsível
- ✅ Ideal para CPU-bound (validação, criptografia)
- ✅ Binário pequeno (std lib)
- ❌ Não escala >10k conexões simultâneas

**Decisão:** Manter sync threads para este projeto (MVP). Async é overkill para validador de CPF.

---

## 5.4 Compressão de Response (gzip/brotli)

### Implementação Rápida

```rust
use flate2::Compression;
use flate2::write::GzEncoder;

fn compress_response(data: &[u8]) -> Vec<u8> {
    let mut encoder = GzEncoder::new(Vec::new(), Compression::fast());
    encoder.write_all(data).unwrap();
    encoder.finish().unwrap()
}

// No response builder:
if req.headers.get("accept-encoding").map(|v| v.contains("gzip")).unwrap_or(false) {
    let compressed = compress_response(body.as_bytes());
    // Adicionar header: Content-Encoding: gzip
}
```

**Ganho:** HTML/JSON tipicamente comprime 70-80% (5KB → 1KB).

---

## 5.5 Observabilidade para Produção

**Por que isso importa:** Escolhemos `FROM scratch` no deploy, eliminando shell e ferramentas de debug. Em produção, observabilidade não é opcional — é sua **única janela** para o sistema.

### Os 3 Pilares

1. **Logs** — O que aconteceu (eventos discretos)
2. **Métricas** — Quanto e quando (agregações numéricas)
3. **Traces** — O caminho da requisição (rastreamento distribuído)

> **Para um guia completo de observabilidade em ambientes Distroless/FROM scratch, consulte:** [`../security/observabilidade-producao.md`](../security/observabilidade-producao.md)

---

### Logs Estruturados (Std Lib Only)

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

### Correlation IDs

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

### Métricas Básicas (Sem Prometheus)

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

### Health Check Verbose

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

### Trade-off: FROM scratch

**Custo:** Sem shell = impossível fazer `docker exec` para debug.

**Compensação:**

1. ✅ Logs estruturados em JSON para stdout (`docker logs -f`)
2. ✅ Endpoint `/health` com informações do sistema
3. ✅ Endpoint `/metrics` para monitoramento externo
4. ✅ Debug **local** completo antes de containerizar

**Para ambientes críticos:** Considere Alpine (~20MB) se precisar de ferramentas de debug em produção. O trade-off de +18MB pode valer a pena.

---

## Resumo de Prioridades

1. **Logs Estruturados** ⭐⭐⭐⭐⭐ — Obrigatório para `FROM scratch`, zero custo de runtime
2. **Thread Pool** ⭐⭐⭐⭐⭐ — Maior ganho de performance/esforço
3. **Métricas Básicas** ⭐⭐⭐⭐ — Essencial para production, baixíssimo overhead
4. **Zero-Copy** ⭐⭐⭐⭐ — Alto ganho para arquivos grandes
5. **Compressão** ⭐⭐⭐ — Médio ganho, fácil de implementar
6. **Async** ⭐ — Só se tráfego justificar (>100k req/s)

---

**Anterior:** [04-camada-deploy.md](04-camada-deploy.md)
