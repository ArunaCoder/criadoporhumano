# 5.2 Zero-Copy File Serving (sendfile syscall)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

## 💭 Pensamento do Engenheiro

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

## Implementação

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

## Cross-platform

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

## Checklist

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
