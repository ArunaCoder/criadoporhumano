# 5.4 Compressão de Response (gzip/brotli)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

## Implementação Rápida

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
