# 5.7 Drenagem de Buffer Residual (TCP Backpressure Handling)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

## 💭 Pensamento do Engenheiro

**O problema descoberto:**

Durante testes de segurança com headers gigantes (10KB), encontramos um **deadlock clássico de protocolo request-response**:

1. Cliente (curl) tenta enviar 10KB via `write()`
2. Buffer TCP do servidor aceita apenas ~2KB
3. Servidor lê 2KB, detecta erro (header muito grande), **retorna erro do parser**
4. Servidor tenta enviar `400 Bad Request` via `stream.write_all()`
5. **Cliente ainda está bloqueado no `write()` original** (8KB restantes não enviados)
6. Cliente não pode ler resposta porque `write()` não completou
7. **DEADLOCK** ⏸️ — teste trava indefinidamente

**Por que acontece:**

TCP usa **flow control** (backpressure) — se o receptor não drena o buffer, o sender bloqueia. No nosso caso:

- Parser lê apenas o necessário para detectar erro
- **Não consome os ~8KB restantes** do buffer TCP
- Cliente fica esperando servidor drenar para completar `write()`
- Servidor fica esperando enviar resposta completa

**Analogia:** Você tenta entregar 10 caixas, mas a porta só cabe 2. Você entrega 2, a pessoa pega só essas 2 e **tenta te dar um recibo** sem pegar as outras 8. Você não consegue pegar o recibo porque suas mãos estão cheias com as 8 caixas restantes. Deadlock.

---

## Soluções por Fase

### Solução 1: Drop Imediato (Fase `estudo` - MVP)

**Abordagem:** Não enviar resposta HTTP — fechar conexão abruptamente.

```rust
// server.rs
match HttpRequest::parse(&mut reader, config) {
    Ok(req) => {
        // Processar request
        let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
        let _ = stream.write_all(response.as_bytes());
        let _ = stream.flush();
    }
    Err(e) => {
        eprintln!("❌ Parse error: {}", e);
        // NÃO enviar resposta — drop do stream fecha conexão
        // Cliente recebe ECONNRESET (connection reset by peer)
    }
}
```

**Como funciona:**

1. Função termina sem enviar resposta
2. `stream` é dropado automaticamente (destructor)
3. Kernel envia `FIN` ou `RST` no socket
4. Cliente recebe sinal de fechamento
5. `write()` do cliente retorna com erro (EPIPE/ECONNRESET)
6. Curl reporta "Empty reply from server"

**Prós:**

- ✅ Zero overhead (nenhuma operação extra)
- ✅ Simples de implementar (remover código)
- ✅ Impossível travar (não tenta comunicação)
- ✅ Adequado para MVP/desenvolvimento

**Contras:**

- ❌ Cliente não recebe resposta HTTP legível
- ❌ Logs do cliente mostram "connection reset" (não 400/431)
- ❌ Não é protocolo HTTP correto (RFC espera resposta)

**Quando usar:**

- ✅ Fase `estudo` (aprendizado/MVP)
- ✅ Testes de segurança (detectar bloqueio)
- ✅ Ambiente não-crítico

---

### Solução 2: Drenar com Limite (Fase `producao` - Recomendado)

**Abordagem:** Consumir até N bytes do lixo residual antes de enviar resposta.

```rust
use std::io::Read;
use std::time::Duration;

fn handle_connection(mut stream: TcpStream, config: &ServerConfig) {
    use std::io::BufReader;

    let mut reader = BufReader::new(&mut stream);

    match HttpRequest::parse(&mut reader, config) {
        Ok(req) => {
            // Processar request válida
            let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.flush();
        }
        Err(e) => {
            eprintln!("❌ Parse error: {}", e);

            // DRENAR BUFFER RESIDUAL com proteções anti-DoS
            const MAX_DISCARD: usize = 16384;  // 16KB limite (proteção DoS)
            const DRAIN_TIMEOUT_MS: u64 = 100; // Timeout curto (proteção Slowloris)

            let mut discarded = 0;
            let mut buf = [0u8; 4096];  // Buffer de leitura (4KB chunks)

            // Configurar timeout curto para não travar em Slowloris
            let _ = stream.set_read_timeout(Some(Duration::from_millis(DRAIN_TIMEOUT_MS)));

            // Drenar até limite ou EOF/timeout
            while discarded < MAX_DISCARD {
                match stream.read(&mut buf) {
                    Ok(0) => break,  // EOF (cliente fechou conexão)
                    Ok(n) => discarded += n,
                    Err(_) => break, // Timeout ou erro de I/O
                }
            }

            // Restaurar timeout original (5s para response)
            let _ = stream.set_read_timeout(Some(Duration::from_secs(5)));

            // Agora enviar resposta HTTP
            let response = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n";
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.flush();
        }
    }
}
```

**Como funciona:**

1. Parser detecta erro e retorna
2. Antes de enviar resposta, **drenar até 16KB** do buffer TCP
3. Usa timeout de 100ms (não trava em ataques Slowloris)
4. Cliente consegue completar `write()` porque servidor está lendo
5. Cliente consegue ler resposta `400 Bad Request`

**Prós:**

- ✅ Cliente recebe resposta HTTP válida (400/431/413)
- ✅ Protocolo HTTP correto (RFC compliance)
- ✅ Logs do cliente mostram código de erro apropriado
- ✅ Proteção DoS (limite de 16KB + timeout)
- ✅ Útil para clientes legítimos com bugs

**Contras:**

- ⚠️ Gasta CPU/memória drenando lixo
- ⚠️ ~100ms de latência extra em erros
- ⚠️ Atacante pode forçar drenagem (mas limitada)

**Quando usar:**

- ✅ Fase `producao` (deploy real)
- ✅ Clientes HTTP diversos (browsers, apps mobile)
- ✅ Logs e observabilidade importam

---

### Solução 3: Shutdown Write-Only (Meio Termo)

**Abordagem:** Enviar resposta e fechar lado de escrita (força flush).

```rust
use std::net::Shutdown;

Err(e) => {
    eprintln!("❌ Parse error: {}", e);

    // Enviar resposta curta
    let response = "HTTP/1.1 400 Bad Request\r\n\r\n";
    let _ = stream.write_all(response.as_bytes());

    // Shutdown write-side (força flush + envia FIN)
    let _ = stream.shutdown(Shutdown::Write);

    // Cliente recebe FIN e para de escrever
}
```

**Prós:**

- ✅ Resposta HTTP enviada
- ✅ Mais rápido que drenar (sem loop)

**Contras:**

- ⚠️ Pode travar se cliente não reagir ao FIN
- ⚠️ Não garante que cliente leia resposta completa
- ⚠️ Comportamento varia entre OSes

**Quando usar:**

- 🤷 Raramente recomendado (pior dos dois mundos)
- ⚠️ Apenas se drenar for muito custoso

---

## Comparação de Trade-offs

| Solução             | Overhead | HTTP Correto | Proteção DoS | Complexidade | Fase       |
| ------------------- | -------- | ------------ | ------------ | ------------ | ---------- |
| Drop Imediato       | Zero     | ❌           | ✅✅✅       | Trivial      | `estudo`   |
| Drenar com Limite   | Baixo    | ✅           | ✅✅         | Moderada     | `producao` |
| Shutdown Write-Only | Mínimo   | ⚠️           | ✅           | Baixa        | Raramente  |

---

## Impacto em Testes de Segurança

**Antes da correção:**

```bash
$ ./test-headers.sh
Testing: Giant header (10KB) ... [TRAVADO POR 5 SEGUNDOS ATÉ TIMEOUT]
^C
```

**Depois (drop imediato):**

```bash
$ ./test-headers.sh
Testing: Giant header (10KB) ... ✓ BLOCKED (Empty reply from server)
```

**Depois (drenar com limite):**

```bash
$ ./test-headers.sh
Testing: Giant header (10KB) ... ✓ BLOCKED (HTTP 431)
```

---

## Checklist de Implementação

### Para Fase `estudo` (Drop Imediato)

- [ ] **REMOVER CÓDIGO:** Em `server.rs`, deletar linhas que enviam resposta em caso de erro:

  ```rust
  Err(e) => {
      eprintln!("❌ Parse error: {}", e);
      // Deletar estas 3 linhas:
      // let response = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n";
      // let _ = stream.write_all(response.as_bytes());
      // let _ = stream.flush();
  }
  ```

- [ ] **VALIDAR:** Rodar testes de segurança:

  ```bash
  cd tests/security
  ./test-headers.sh  # Deve completar sem travar
  ```

- [ ] **DOCUMENTAR:** Adicionar comentário explicando a escolha:
  ```rust
  Err(e) => {
      eprintln!("❌ Parse error: {}", e);
      // MVP: Drop imediato (sem resposta HTTP) para evitar deadlock TCP.
      // Cliente recebe ECONNRESET. Em produção, implementar drenagem de buffer.
      // Ver: docs/01-validador-cpf-basico/05-otimizacoes-avancadas/07-drenagem-buffer-residual.md
  }
  ```

---

### Para Fase `producao` (Drenar com Limite)

- [ ] **ADICIONAR FUNÇÃO AUXILIAR:** Em `server.rs`:

  ```rust
  /// Drena até MAX_DISCARD bytes do stream para evitar deadlock TCP.
  /// Protege contra DoS com limite de bytes e timeout.
  fn drain_residual_buffer(stream: &mut TcpStream) {
      const MAX_DISCARD: usize = 16384;  // 16KB
      const DRAIN_TIMEOUT_MS: u64 = 100; // 100ms

      let mut discarded = 0;
      let mut buf = [0u8; 4096];

      let _ = stream.set_read_timeout(Some(Duration::from_millis(DRAIN_TIMEOUT_MS)));

      while discarded < MAX_DISCARD {
          match stream.read(&mut buf) {
              Ok(0) => break,
              Ok(n) => discarded += n,
              Err(_) => break,
          }
      }

      // Restaurar timeout de 5s
      let _ = stream.set_read_timeout(Some(Duration::from_secs(5)));
  }
  ```

- [ ] **INTEGRAR NO ERROR HANDLING:**

  ```rust
  Err(e) => {
      eprintln!("❌ Parse error: {}", e);

      // Drenar buffer residual antes de responder
      drain_residual_buffer(&mut stream);

      // Agora enviar resposta HTTP
      let response = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n";
      let _ = stream.write_all(response.as_bytes());
      let _ = stream.flush();
  }
  ```

- [ ] **TELEMETRIA:** Adicionar contador de bytes drenados:

  ```rust
  use std::sync::atomic::{AtomicU64, Ordering};

  static BYTES_DRAINED: AtomicU64 = AtomicU64::new(0);

  // Na função drain_residual_buffer:
  while discarded < MAX_DISCARD {
      match stream.read(&mut buf) {
          Ok(n) => {
              discarded += n;
              BYTES_DRAINED.fetch_add(n as u64, Ordering::Relaxed);
          }
          // ...
      }
  }

  // Expor em /metrics:
  // drain_residual_bytes_total 1234567
  ```

- [ ] **TESTE DE STRESS:** Verificar que não há travamento sob carga:

  ```bash
  # Terminal 1: Servidor
  cargo run --release

  # Terminal 2: Ataque com headers gigantes
  for i in {1..1000}; do
      curl -H "X-Giant: $(python -c 'print("A"*10000)')" http://localhost:8080/ &
  done

  # Verificar:
  # - Nenhum request trava
  # - Todos retornam 431 ou connection reset
  # - CPU e memória estáveis
  ```

- [ ] **BENCHMARK:** Medir overhead da drenagem:

  ```bash
  # Requests inválidas com drenagem
  wrk -s scripts/invalid_giant_headers.lua -t4 -c100 -d30s http://localhost:8080

  # Comparar latência p99:
  # - Com drenagem: ~105ms (100ms drain + 5ms processing)
  # - Sem drenagem (drop): ~1ms
  # Trade-off: 100ms overhead para protocolo HTTP correto
  ```

---

## Decisão de Design: Por Fase

| Fase       | Solução Recomendada | Justificativa                                           |
| ---------- | ------------------- | ------------------------------------------------------- |
| `estudo`   | Drop Imediato       | Zero complexidade, adequado para MVP/testes             |
| `producao` | Drenar com Limite   | HTTP correto, logs úteis, proteção DoS                  |
| Crítico    | Drenar + Telemetria | Monitorar ataques, ajustar limites baseado em profiling |

---

## Lições Aprendidas

**Este bug foi descoberto através de testes reais**, não antecipado durante design inicial. Isso ilustra:

1. **Testes de segurança são essenciais** — revelam casos de borda que não aparecem em testes normais
2. **TCP é complexo** — flow control e backpressure criam deadlocks sutis
3. **Protocolos request-response têm armadilhas** — enviar resposta sem consumir input é perigoso
4. **MVP pode usar shortcuts** — drop imediato é aceitável para desenvolvimento
5. **Produção exige robustez** — drenar buffer é o comportamento correto de um servidor HTTP

**Documentar problemas descobertos durante implementação é tão importante quanto documentar o design original.**
