# 5.1 Thread Pool (Paralelização Multi-Core)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

## 💭 Pensamento do Engenheiro

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

## Opção A: Crate `rayon` (Recomendado)

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

## Opção B: Thread Pool Manual (Educacional)

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

## Trade-offs

**Quando usar thread pool:**

- ✅ CPU-bound: validação de CPF, criptografia, compressão
- ✅ Multi-core disponível (servidor production)
- ✅ Tráfego alto (>5k req/s)

**Quando NÃO usar:**

- ❌ I/O-bound: 99% do tempo esperando disco/network (use async)
- ❌ Single-core VPS (overhead > ganho)
- ❌ Tráfego baixo (<1k req/s)

## Checklist

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
