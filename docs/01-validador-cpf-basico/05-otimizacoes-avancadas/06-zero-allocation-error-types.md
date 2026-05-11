# 5.6 Zero-Allocation Error Types (Enum de Erros)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

## 💭 Pensamento do Engenheiro

**O problema:**

Código atual usa `Result<T, String>` com mensagens dinâmicas:

```rust
return Err(format!("Method not allowed: {}", method));  // Aloca no heap
return Err(format!("Error reading: {}", e));            // Aloca no heap
```

**Custo por erro:**

- `format!()` aloca ~50-100 bytes no heap
- Em requisições válidas: custo zero (caminho feliz)
- **Sob ataque DoS:** milhões de erros/segundo = saturação do allocator

**Quando isso importa:**

- ❌ Tráfego normal (0.01-0.1% de erros) → irrelevante
- ❌ Fase de desenvolvimento → contexto rico vale mais
- ✅ **Sob ataque massivo** (50%+ de requests malformadas) → pode ser gargalo

**Trade-off filosófico:**

> "Otimize o caminho feliz primeiro. Caminho de erro pode alocar."

Mas em servidores HTTP, **ataques transformam o caminho de erro no caminho comum**. Se atacante consegue forçar 100k erros/segundo, alocações viram problema real.

---

## Implementação: ParseError Enum

### Estado Atual (Fase `estudo`)

```rust
// request.rs
pub fn parse(
    reader: &mut BufReader<&mut TcpStream>,
    config: &ServerConfig,
) -> Result<Self, String> {  // ← String alocada dinamicamente
    // ...
    return Err(format!("Method not allowed: {}", method));
}
```

### Estado Futuro (Produção sob ataque)

```rust
// error.rs - Novo arquivo
#[derive(Debug)]
pub enum ParseError {
    // Zero-cost variants (sem alocação)
    LineTooLong,
    UriTooLong,
    TooManyHeaders,
    HeaderTooLarge,
    VersionNotSupported,
    PathTraversal,

    // Variants com contexto (aloca apenas quando necessário)
    InvalidMethod(String),
    IoError(std::io::Error),

    // Mensagem genérica (para casos raros)
    Other(String),
}

impl std::fmt::Display for ParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            Self::LineTooLong => write!(f, "Request line exceeds maximum size"),
            Self::UriTooLong => write!(f, "414 URI Too Long"),
            Self::InvalidMethod(m) => write!(f, "Method not allowed: {}", m),
            Self::IoError(e) => write!(f, "I/O error: {}", e),
            // ... outros casos
        }
    }
}

impl std::error::Error for ParseError {}

// request.rs - Refatorado
pub fn parse(
    reader: &mut BufReader<&mut TcpStream>,
    config: &ServerConfig,
) -> Result<Self, ParseError> {  // ← Enum, não String
    // ...

    // Erros comuns: zero allocation
    if line.len() >= MAX_LINE_SIZE {
        return Err(ParseError::UriTooLong);  // ← Só copia enum tag (8 bytes na stack)
    }

    // Erros raros: aloca apenas quando precisa de contexto
    if !ALLOWED_METHODS.contains(&method.as_str()) {
        return Err(ParseError::InvalidMethod(method.to_string()));  // ← Aloca, mas é raro
    }
}
```

---

## Benefícios Quantificados

**Cenário: Ataque DoS com 100k requests malformadas/segundo**

| Implementação      | Alocações/seg                | Pressão no Allocator |
| ------------------ | ---------------------------- | -------------------- |
| `String` (atual)   | 100k × 80 bytes = **8 MB/s** | Alto (fragmentação)  |
| `Enum` (otimizado) | 0 bytes (stack only)         | Zero                 |

**Ganho:** Elimina 100% das alocações em erros comuns (linha grande, método inválido, etc).

---

## Trade-offs Honestos

**Prós:**

- ✅ Zero alocação para erros frequentes sob ataque
- ✅ Type-safe: compilador força tratamento de cada caso
- ✅ Performance previsível mesmo sob DoS
- ✅ Facilita telemetria (contar erros por tipo)

**Contras:**

- ❌ Código mais verboso (enum + impl Display + match arms)
- ❌ Perde flexibilidade de mensagens dinâmicas ad-hoc
- ❌ Refatoração trabalhosa (mudar assinaturas em todo código)
- ❌ Overkill para fase de desenvolvimento

---

## Quando Implementar

**✅ Implemente SE:**

- Profiling mostra `format!()` consumindo >5% do tempo sob carga
- Servidor está em produção recebendo ataques reais
- Todas otimizações de alto impacto já foram feitas (thread pool, cache, keep-alive)

**❌ NÃO implemente SE:**

- Ainda em fase `estudo` (contexto rico > micro-otimização)
- Não há evidência de gargalo em error handling
- Há otimizações de maior impacto pendentes

---

## Checklist de Implementação

- [ ] **MEDIR PRIMEIRO:** Profiling com `cargo flamegraph` sob ataque simulado:

  ```bash
  # Gerar tráfego malicioso
  while true; do
      echo "INVALID_REQUEST" | nc localhost 8080
  done &

  # Rodar com profiling
  cargo flamegraph --bin api

  # Verificar se `format` aparece como hotspot (>5% samples)
  ```

- [ ] **CRIAR ENUM:** Arquivo `backend/shared/src/http/error.rs`:

  ```rust
  #[derive(Debug)]
  pub enum ParseError {
      LineTooLong,
      UriTooLong,
      TooManyHeaders,
      HeaderTooLarge,
      VersionNotSupported,
      PathTraversal,
      SuspiciousPath,
      InvalidMethod(String),
      InvalidContentLength,
      PayloadTooLarge,
      IoError(std::io::Error),
      Other(String),
  }
  ```

- [ ] **IMPLEMENTAR TRAITS:**

  ```rust
  impl std::fmt::Display for ParseError { /* ... */ }
  impl std::error::Error for ParseError {}

  impl From<std::io::Error> for ParseError {
      fn from(e: std::io::Error) -> Self {
          Self::IoError(e)
      }
  }
  ```

- [ ] **REFATORAR PARSE:** Substituir `Result<T, String>` por `Result<T, ParseError>`:

  ```rust
  // Antes
  return Err("414 URI Too Long".to_string());

  // Depois
  return Err(ParseError::UriTooLong);
  ```

- [ ] **ATUALIZAR CHAMADORES:** Em `server.rs`:

  ```rust
  match HttpRequest::parse(&mut reader, config) {
      Ok(req) => { /* ... */ }
      Err(e) => {
          eprintln!("Parse error: {}", e);  // Display trait formata
          send_error_response(&mut stream, e.status_code());
      }
  }
  ```

- [ ] **ADICIONAR MÉTODOS AUXILIARES:**

  ```rust
  impl ParseError {
      pub fn status_code(&self) -> u16 {
          match self {
              Self::UriTooLong => 414,
              Self::PayloadTooLarge => 413,
              Self::TooManyHeaders | Self::HeaderTooLarge => 431,
              Self::InvalidMethod(_) => 405,
              _ => 400,
          }
      }

      pub fn is_client_error(&self) -> bool {
          !matches!(self, Self::IoError(_))
      }
  }
  ```

- [ ] **TELEMETRIA:** Adicionar contadores por tipo de erro:

  ```rust
  use std::sync::atomic::{AtomicU64, Ordering};

  static ERRORS_URI_TOO_LONG: AtomicU64 = AtomicU64::new(0);
  static ERRORS_INVALID_METHOD: AtomicU64 = AtomicU64::new(0);

  fn log_error(e: &ParseError) {
      match e {
          ParseError::UriTooLong => ERRORS_URI_TOO_LONG.fetch_add(1, Ordering::Relaxed),
          ParseError::InvalidMethod(_) => ERRORS_INVALID_METHOD.fetch_add(1, Ordering::Relaxed),
          // ...
      };
  }
  ```

- [ ] **BENCHMARK PÓS-REFATORAÇÃO:** Comparar antes vs depois:

  ```bash
  # Teste de stress com requests inválidas
  wrk -s scripts/invalid_requests.lua -t4 -c100 -d30s http://localhost:8080

  # Verificar:
  # - Latência p99 diminuiu?
  # - Memória heap estável sob ataque?
  # - CPU usage menor?
  ```

- [ ] **VALIDAÇÃO:** Confirmar que erro messages ainda são úteis:
  ```bash
  curl -X PATCH http://localhost:8080/  # Deve logar "InvalidMethod: PATCH"
  curl --path-as-is http://localhost:8080/../secret.txt  # Deve logar "PathTraversal"
  ```

---

## Exemplo Completo: Antes vs Depois

**Antes (String - Fase `estudo`):**

```rust
// ✅ Simples, mensagens ricas
// ❌ Aloca em todo erro

if !ALLOWED_METHODS.contains(&method.as_str()) {
    return Err(format!("Method not allowed: {}", method));  // ~80 bytes alocados
}

if line.len() >= MAX_LINE_SIZE {
    return Err("414 URI Too Long".to_string());  // ~20 bytes alocados
}
```

**Depois (Enum - Produção):**

```rust
// ✅ Zero alocação para casos comuns
// ✅ Type-safe, telemetria fácil
// ❌ Mais verboso

if !ALLOWED_METHODS.contains(&method.as_str()) {
    return Err(ParseError::InvalidMethod(method.to_string()));  // Aloca só quando raro
}

if line.len() >= MAX_LINE_SIZE {
    return Err(ParseError::UriTooLong);  // Stack-only (8 bytes discriminant)
}
```

---

## Filosofia de Otimização

**Lembre-se:**

1. **Premature optimization is the root of all evil** (Donald Knuth)
   - Não implemente até profiling mostrar necessidade

2. **Otimize o caminho feliz primeiro**
   - Requisições válidas > requisições inválidas

3. **Mas prepare-se para quando o erro vira norma**
   - Ataques transformam "edge case" em "main case"

**Esta otimização é para Fase 2 (produção sob ataque), não Fase 1 (estudo).**
