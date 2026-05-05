# 🦀 Camada 2: Lógica de Negócio e Routing

**Objetivo:** Validação pura de dados + Routing manual.

---

## 📋 Decisões Técnicas desta Camada

### Routing Manual vs Framework (Axum/Actix)

**Decisão:** Pattern matching manual com `match`.

**Justificativa:**

- Apenas 3-4 rotas no total
- Zero dependências (objetivo educacional)
- Controle total sobre parsing e validação
- Performance idêntica para poucos endpoints

**Solução ignorada:** Frameworks de routing

- **Axum:** +1.5MB, abstração excessiva para 4 rotas
- **Actix-web:** +2MB, overkill para caso de uso simples
- **Trade-off:** Produtividade vs aprendizado (escolhemos aprendizado)

### JSON Parsing: Manual vs Serde

**Decisão inicial:** Parsing manual com `split`/`find`.

**Justificativa:**

- Payload extremamente simples: `{"cpf":"..."}`
- Parsing via string manipulation é trivial
- Evita +500KB de `serde_json` no binário

**Fallback planejado:** Se precisar parsear JSON complexo, adicionar `serde_json` é 1 linha de mudança.

**Solução ignorada (por enquanto):** `serde_json`

- **Custo:** +500KB no binário
- **Benefício:** Robustez em edge cases, validação automática
- **Quando adicionar:** Se precisar suportar payloads complexos ou múltiplos formatos

### State Management: Global Mutable vs Imutável

**Decisão:** Sem estado global mutável.

**Justificativa:**

- Validação de CPF é função pura (stateless)
- Sem necessidade de cache ou sessões
- Evita complexidade de `Arc<Mutex<T>>` ou `RwLock`
- Cada request é independente

**Solução ignorada:** Cache de resultados

- **Motivo:** CPF tem apenas 11 dígitos = ~100 bilhões de combinações
- **Impraticável:** Cache seria maior que a RAM disponível
- **Desnecessário:** Cálculo é O(1) e <1µs

---

## 2.1 Routing Manual

### Passo 14: Implementar Router

- [ ] Criar função `route_request(req: HttpRequest) -> HttpResponse`
- [ ] Usar `match` para decidir handler:
  ```rust
  match (req.method.as_str(), req.path.as_str()) {
      ("GET", "/") => serve_index(),
      ("GET", "/health") => health_check(),
      ("POST", "/api/validate") => validate_cpf_handler(req),
      ("OPTIONS", _) => cors_preflight(), // CORS preflight
      _ => HttpResponse::not_found(),
  }
  ```
- [ ] **CRÍTICO:** Adicionar CORS headers em TODAS as respostas:
  ```rust
  // Criar função helper
  fn add_cors_headers(mut response: HttpResponse) -> HttpResponse {
      response.headers.insert("Access-Control-Allow-Origin".to_string(), "*".to_string());
      response.headers.insert("Access-Control-Allow-Methods".to_string(), "GET, POST, OPTIONS".to_string());
      response.headers.insert("Access-Control-Allow-Headers".to_string(), "Content-Type".to_string());
      response
  }
  ```
- [ ] Chamar `route_request()` em `handle_connection`
- [ ] Testar: `curl http://localhost:8080/health` deve retornar 200

### Passo 15: Health Check Handler

- [ ] Implementar `fn health_check() -> HttpResponse`
- [ ] Retornar JSON: `{"status":"ok","service":"cpf-validator"}`
- [ ] Testar: `curl http://localhost:8080/health | jq`

---

## 2.2 Integração com Validador de CPF

### Passo 16: JSON Parsing Manual (Request)

- [ ] Em `validate_cpf_handler`: parsear body JSON manualmente
- [ ] **CRÍTICO:** Validar Content-Type antes de parsear:
  ```rust
  let content_type = req.headers.get("content-type")
      .ok_or("Content-Type required")?;
  if !content_type.contains("application/json") {
      return HttpResponse::bad_request();
  }
  ```
- [ ] Procurar substring `"cpf"` no body
- [ ] Extrair valor entre aspas: `"cpf":"123.456.789-09"`
- [ ] **CRÍTICO:** Tratar escape sequences:
  ```rust
  fn extract_json_string(body: &str, key: &str) -> Option<String> {
      let pattern = format!("\"{}\":\"", key);
      let start = body.find(&pattern)? + pattern.len();
      let end = body[start..].find('"')?;
      let value = &body[start..start + end];
      Some(value.replace("\\\\", "\\").replace("\\\"", "\""))
  }
  ```
- [ ] **Alternativa:** Use `serde_json` apenas para parsing (é std-adjacent, ~500KB)
- [ ] Validar que conseguiu extrair CPF do JSON

### Passo 17: Chamar Validador

- [ ] Importar: `use shared_utils::validators::cpf::validate_cpf`
- [ ] Chamar função: `let is_valid = validate_cpf(&cpf_value)`
- [ ] Construir resposta JSON manualmente:
  ```rust
  let response_body = format!(
      r#"{{"valid":{},"cpf":"{}"}}"#,
      is_valid, cpf_value
  );
  ```
- [ ] Retornar `HttpResponse::ok(response_body)`

### Passo 18: Teste End-to-End da API

- [ ] Rodar servidor: `cargo run`
- [ ] Testar válido: `curl -X POST -H "Content-Type: application/json" -d '{"cpf":"12345678909"}' http://localhost:8080/api/validate`
- [ ] Testar inválido: `curl -X POST -d '{"cpf":"111.111.111-11"}' http://localhost:8080/api/validate`
- [ ] Validar que retorna `{"valid":true/false,"cpf":"..."}`

### Passo 19: Error Handling Robusto

- [ ] Adicionar tratamento para body vazio
- [ ] Adicionar tratamento para JSON malformado
- [ ] Retornar `HttpResponse::bad_request()` com mensagem apropriada
- [ ] **CRÍTICO:** Adicionar logging estruturado de erros:
  ```rust
  fn log_error(method: &str, path: &str, error: &str) {
      eprintln!("[ERROR] {} {} - {}", method, path, error);
  }
  ```
- [ ] **CRÍTICO:** Nunca vazar detalhes internos ao cliente:
  ```rust
  // Ruim: return Err(format!("Database error: {}", e));
  // Bom: log_error(&e); return HttpResponse::server_error();
  ```
- [ ] Testar: `curl -X POST -d 'lixo' http://localhost:8080/api/validate` deve retornar 400
- [ ] Testar: `curl -X POST -d '{}' http://localhost:8080/api/validate` deve retornar 400 (CPF ausente)

---

## 2.3 Configuração via Ambiente

### Passo 19.1: Suporte a Variáveis de Ambiente

- [ ] Modificar `main.rs` para ler porta de variável de ambiente:

  ```rust
  fn main() {
      let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
      let addr = format!("0.0.0.0:{}", port);

      if let Err(e) = http::server::start_server(&addr) {
          eprintln!("Erro ao iniciar servidor: {}", e);
          std::process::exit(1);
      }
  }
  ```

- [ ] **CRÍTICO:** Bind em `0.0.0.0` (não `127.0.0.1`) para permitir conexões externas em containers
- [ ] Adicionar flag `--health` para healthcheck do Docker:
  ```rust
  fn main() {
      let args: Vec<String> = std::env::args().collect();
      if args.len() > 1 && args[1] == "--health" {
          // Tenta conectar em localhost:PORT
          match std::net::TcpStream::connect("127.0.0.1:8080") {
              Ok(_) => std::process::exit(0),
              Err(_) => std::process::exit(1),
          }
      }
      // ... resto do código
  }
  ```
- [ ] Testar: `PORT=9000 cargo run` deve iniciar na porta 9000
- [ ] Testar: `./identity-api --health` deve retornar exit code 0 se servidor está rodando

---

**Anterior:** [01-camada-networking.md](01-camada-networking.md)
**Próximo:** [03-camada-frontend.md](03-camada-frontend.md)
