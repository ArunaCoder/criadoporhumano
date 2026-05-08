# 📊 Decisões Arquiteturais & Métricas

## Decisões Técnicas Importantes

### 1. HTTP em `backend/shared` vs `backend/api`

**Decisão:** Implementar em `backend/shared/src/http/` (compartilhado).

**Justificativa:**

- Iteração rápida sem preocupação com API pública estável
- Aprender detalhes de implementação antes de abstrair prematuramente
- Praticar refatoração futura quando houver casos de uso reais
- Princípio: "Make it work, make it right, make it fast"

**Benefício:** Código HTTP compartilhado desde o início facilita adicionar novos serviços (CLI, workers) sem duplicação.

---

### 2. Parser HTTP Manual vs httparse

**Decisão:** Parser completamente manual usando apenas std lib.

**Justificativa:**

- Objetivo educacional: entender o protocolo HTTP na íntegra
- Controle total sobre parsing e validações
- Zero dependências externas
- Trade-off consciente: robustez vs aprendizado

**Limitações conhecidas:**

- Não suporta chunked encoding
- Requer `Content-Length` obrigatório em POSTs
- Assume requests bem-formados
- Não suporta HTTP/2 ou HTTP/3

**Adequado para:** MVPs, APIs internas, casos de uso controlados.

---

### 3. Single-Threaded vs Thread Pool

**Decisão:** Implementação single-threaded (bloqueante) inicial.

**Justificativa:**

- Para validador de CPF, resposta é <1ms
- Simplicidade de implementação e debugging
- Suficiente para ~1000 req/s (mais que adequado para MVP)

**Quando mudar:**

- Se profiling mostrar gargalo de CPU
- Se precisar escalar para >5000 req/s
- Solução: adicionar `std::thread::spawn` por request ou pool manual

---

### 4. JSON Parsing Manual vs serde_json

**Decisão:** Tentar parsing manual primeiro, fallback para `serde_json` se muito complexo.

**Justificativa:**

- Payload extremamente simples: `{"cpf":"..."}`
- Parsing via `split` e `find` é trivial
- `serde_json` adiciona ~500KB ao binário
- Se precisar, adicionar é fácil (apenas 1 linha de mudança)

---

### 5. BufReader vs Parsing Manual de Bytes

**Decisão:** Usar `BufReader` da std lib para leitura de linhas.

**Dilema pedagógico: usar BufReader não "esconde" o aprendizado?**

Resposta honesta: **depende do que você quer aprender**.

Se o objetivo é **aprender como TCP funciona em baixo nível**, então sim — implementar seu próprio buffer circular ensinaria sobre:

- Como syscalls `read()` funcionam
- Gerenciamento manual de buffers
- Estados de parsing (procurando CRLF, bytes parciais, etc.)

Mas o objetivo deste projeto é **aprender HTTP**, não TCP. Dois níveis diferentes:

- **Nível TCP:** "Como transformar stream de bytes fragmentado em linhas de texto?"
- **Nível HTTP:** "Como interpretar `GET /api/users HTTP/1.1` e transformar em estrutura útil?"

**Usar BufReader não tira o aprendizado de HTTP.** Você ainda vai:

- Parsear manualmente a request line (split por espaços)
- Validar método, path, versão (segurança!)
- Parsear headers linha por linha (split por `:`)
- Ler body baseado em Content-Length
- Construir responses HTTP manualmente

**O que BufReader esconde (intencionalmente):**

- Gerenciamento de buffer circular
- Detecção de newline em meio a bytes fragmentados
- Validação de UTF-8

**O que você ainda implementa do zero:**

- Toda a lógica do protocolo HTTP
- Validações de segurança (DoS, path traversal, etc.)
- Construção de responses

**Analogia:** Usar BufReader é como usar `String` em vez de manipular `Vec<u8>` diretamente. Você poderia aprender mais sobre UTF-8 implementando String do zero, mas isso não é o objetivo quando você quer aprender sobre parsing de protocolos.

**Princípio de engenharia:** "Use abstração no nível N-1 para focar em aprender o nível N". Você está aprendendo HTTP (nível N), então usa abstrações de I/O (nível N-1). Se quisesse aprender I/O, usaria abstrações de syscalls (nível N-2).

**Decisão consciente:** Este projeto aceita BufReader como "biblioteca confiável" para focar energia no problema interessante (HTTP + segurança), não no problema resolvido (buffering de I/O).

**Mapa de aprendizado de Rust ao longo do projeto:**

Implementar buffer manualmente ensinaria principalmente **unsafe code** (ponteiros, Vec raw) e **algoritmos de circular buffer**. Mas ao usar BufReader e focar em HTTP, você vai mergulhar em:

**Camada Networking (Passos 1-13):**

- **Ownership & Borrowing:** passar `TcpStream` entre funções, emprestar vs consumir
- **Result<T, E> e ? operator:** error handling em cada etapa de parsing
- **Traits:** `Read`, `BufRead`, `Write` (você usa, entende como funcionam)
- **Pattern matching:** parsear request line com `split()` e destructuring
- **Structs e impl blocks:** `HttpRequest`, `HttpResponse` com métodos
- **Lifetimes:** aparecem quando você tenta retornar referências de headers
- **String vs &str:** decisões de alocação (quando copiar, quando emprestar)
- **HashMap:** armazenar headers, lookups eficientes
- **Enums:** modelar métodos HTTP (`GET`, `POST`) e status codes
- **Option<T>:** headers opcionais, Content-Length pode não existir
- **Iterators:** `lines()`, `split()`, `take()`, `filter()`

**Camada Lógica (Passos 14-20):**

- **Match expressions:** routing (mapear path → handler)
- **Closures:** callbacks de rotas
- **Error types customizados:** criar `ValidationError`, implementar trait `Error`
- **Trait objects:** `Box<dyn Error>` para unificar erros
- **Generics:** funções que aceitam `impl Into<String>`
- **derive macros:** `#[derive(Debug, Clone)]`
- **Testes unitários:** `#[cfg(test)]`, `assert_eq!`

**Camada Frontend (Passos 21-26):**

- **Static files:** `include_str!()` macro para embedar HTML/CSS/JS
- **Serialization:** JSON manual ou com `serde` (se adicionar)

**Todas as camadas:**

- **Module system:** `pub`, `mod`, visibilidade
- **Constants:** `const MAX_LINE_SIZE`
- **Documentation comments:** `///` para gerar docs
- **Cargo features:** build profiles, workspaces

**Features que você NÃO usaria mesmo implementando buffer manualmente:**

- Unsafe code (você pode fazer o projeto inteiro em safe Rust)
- Raw pointers (desnecessário)
- Async/await (escolhemos blocking I/O)
- Macros declarativas (não é essencial para HTTP)

**Conclusão:** BufReader não esconde nenhum conceito exclusivo de Rust. Ele mesmo usa traits (`Read`, `BufRead`) que você vai encontrar e usar em todo o projeto. A sintaxe e ferramentas de Rust aparecem **muito mais** no parsing de HTTP, validações, routing, error handling, etc. — que são 90% do código que você vai escrever.

---

### 6. Normalização de Headers: to_lowercase() vs Alternativas

**Decisão:** Normalizar headers com `to_lowercase()` apesar do custo de alocação.

#### 🔬 Análise do Problema

**Estado atual:**

```rust
headers.insert(
    key.trim().to_lowercase(), // ← Aloca String nova (heap allocation)
    value.trim().to_string()
);
```

**O que acontece em baixo nível:**

Para cada header recebido (média de 15 por request):

1. `to_lowercase()` cria uma **nova String** no heap (~24 bytes de metadata + tamanho da chave)
2. Copia caracteres convertendo para minúsculas
3. HashMap toma ownership dessa String

**Custo agregado:**

- 15 headers × 24 bytes de overhead = **360 bytes de alocação por request**
- Em 10k req/s = **3.6 MB/s de alocações no heap**
- Em 100k req/s = **36 MB/s** (começa a ser relevante)

#### 🎯 Por que isso acontece?

HTTP headers são **case-insensitive** por especificação (RFC 7230):

```
Content-Type: application/json  ← Válido
content-type: application/json  ← Também válido
CONTENT-TYPE: application/json  ← Também válido
```

Para garantir lookup consistente, normalizamos tudo para lowercase. Alternativas existem, mas cada uma tem trade-offs.

#### 🛠️ Alternativas Avaliadas

##### Opção A: Comparação Case-Insensitive no Lookup

```rust
// Guardar original (sem normalização)
headers.insert(key.trim().to_string(), value.trim().to_string());

// Buscar com iteração
let content_type = headers.iter()
    .find(|(k, _)| k.eq_ignore_ascii_case("content-type"))
    .map(|(_, v)| v);
```

**Trade-offs:**

- ✅ **Economia:** Zero alocações extras
- ❌ **Performance:** Lookup de **O(1) → O(n)** (desastre!)
- ❌ **Complexidade:** Código verboso em todo lugar que busca header

**Veredito:** Perder O(1) lookup é inaceitável. Headers são consultados centenas de vezes por request.

##### Opção B: Índice Duplo (Preservar Original)

```rust
struct Headers {
    lookup: HashMap<String, String>,    // Lowercase para busca
    original: HashMap<String, String>,  // Case original para debug
}
```

**Trade-offs:**

- ✅ **Performance:** Mantém O(1) lookup
- ✅ **Debug:** Preserva case original
- ❌ **Memória:** Dobra uso de RAM (2× HashMaps)
- ❌ **Complexidade:** API mais complexa

**Veredito:** Dobrar memória para preservar case que só importa em debug não compensa.

##### Opção C: String Interning (Avançado)

```rust
// Usar crate 'string-cache' ou pool de strings
// Pre-aloca strings comuns: "content-type", "host", "user-agent"
lazy_static! {
    static ref COMMON_HEADERS: HashMap<&'static str, &'static str> = {
        hashmap!{
            "content-type" => "content-type",
            "host" => "host",
            // ...
        }
    };
}
```

**Trade-offs:**

- ✅ **Performance:** Zero alocações para headers comuns (~80% dos casos)
- ❌ **Complexidade:** Gerenciamento de pool, crate externo
- ❌ **Overhead:** Lookup extra no pool antes de alocar

**Veredito:** Engenharia avançada que só vale em escala massiva (1M+ req/s).

#### 📊 Decisão: **NÃO IMPLEMENTAR**

**Justificativa:**

1. **Custo vs Benefício Negativo:**
   - Economia: 360 bytes/req = **0.0003% de memória** em servidor moderno
   - Rust allocator (jemalloc) é extremamente eficiente para pequenas alocações
   - Perder O(1) lookup ou dobrar memória é muito pior que 360 bytes

2. **Prioridades de Otimização:**

   ```
   Alto impacto (1000x+):  Syscalls, I/O de disco, network latency
   Médio impacto (10-100x): Algoritmos O(n²), locks desnecessários
   Baixo impacto (1-5x):    Alocações pequenas (este caso)
   ```

3. **Quando Revisitar:**
   - ✓ Após profiling mostrar que alocações de headers são gargalo (improvável)
   - ✓ Servidor processando 100k+ req/s (escala gigante)
   - ✓ Todas otimizações de alto impacto já implementadas

4. **Otimizações de ALTO IMPACTO ainda não feitas:**
   - HTTP keep-alive (reduz overhead de TCP handshake — **implementado no Passo 9.3**)
   - Cache de arquivos em memória (elimina I/O de disco — **implementado no Passo 13.1**)
   - Thread pool (paraleliza requests em multi-core — **Fase 2: produção, ver 05-otimizacoes-avancadas.md**)
   - Zero-copy file serving via sendfile() (elimina cópia memória — **Fase 2: produção, requer crate, ver 05-otimizacoes-avancadas.md**)

**Veredito Final:** Economia marginal (~1-2% de performance em melhor caso, **perda** no pior caso). **Não priorizar** — focar em otimizações que dão 10x-1000x de ganho primeiro.

---

## Limitações Conhecidas

### Segurança

- ⚠️ Sem rate limiting (adicionar em produção)
- ⚠️ Sem autenticação (adequado para API pública de validação)
- ⚠️ **Slowloris parcialmente mitigado:** read/write timeout de 5s reduz janela de ataque, mas não elimina completamente. Para mitigação completa, usar reverse proxy (nginx/caddy) com rate limiting.
- ✅ Proteção contra OOM via `MAX_BODY_SIZE` e `MAX_LINE_SIZE`
- ✅ Proteção contra header flooding via `MAX_HEADERS`
- ✅ Validação de método HTTP (whitelist)
- ✅ Validação de versão HTTP
- ✅ Proteção contra path traversal
- ✅ `Connection: close` previne vazamento de recursos
- ✅ Docker com usuário não-root e `--read-only`

### Performance

- ⏱️ Single-threaded: máx ~1-5k req/s (suficiente para MVP)
- 💾 Sem cache de resultados (CPF sempre é recalculado)
- ✅ **HTTP keep-alive:** Implementado no Passo 9.3 (reduz latência 10-100x)
- ✅ **Cache de arquivos estáticos:** Implementado no Passo 13.1 (reduz I/O 1000x)
- 📊 **Thread pool:** Planejado para Fase 2 (escala multi-core)

### Compatibilidade HTTP

- ❌ Não suporta: chunked encoding, HTTP/2, HTTP/3, WebSockets
- ❌ Não suporta: multipart/form-data, cookies, sessions
- ✅ Suporta: HTTP keep-alive (Connection: keep-alive com timeout)
- ✅ Suporta: GET, POST, HEAD, OPTIONS
- ✅ Suporta: Headers básicos, JSON, CORS
- ✅ Suporta: HTTP/1.0 e HTTP/1.1

---

## Métricas de Sucesso

Ao final do projeto, você deve ter:

### Tamanho

- ✅ Binário final: **< 3MB** (stripped, MUSL)
- ✅ Imagem Docker: **< 5MB** (FROM scratch)
- ✅ Assets embutidos: **< 50KB** (HTML + CSS + JS)

### Performance

- ✅ Tempo de resposta: **< 5ms** (média)
- ✅ Throughput: **> 1000 req/s** (single-threaded)
- ✅ RAM em idle: **< 5MB**
- ✅ Cold start: **< 100ms**

### Arquitetura

- ✅ Zero dependências de runtime (binário estático)
- ✅ Zero frameworks externos (só std lib + shared)
- ✅ Single binary distribution
- ✅ Funciona em qualquer Linux (MUSL)

### Educacional

- ✅ Entendimento profundo de TCP/IP
- ✅ Entendimento profundo de HTTP
- ✅ Capacidade de debugar problemas de rede
- ✅ Experiência com cross-compilation (MUSL)
- ✅ Domínio de Docker multi-stage builds

---

## Roadmap de Refatoração Futura

### Fase 1: Validação (atual)

- Implementar tudo em `backend/api` com `backend/shared` para código comum
- Validar conceitos e arquitetura
- Obter métricas reais

### Fase 2: Extração (quando houver 2+ casos de uso)

- HTTP já está em `backend/shared/` (compartilhado desde o início)
- Criar API pública estável
- Adicionar testes de integração

### Fase 3: Otimização (se necessário)

- Adicionar thread pool manual
- Implementar cache de resultados
- Adicionar rate limiting
- Considerar async (tokio) se houver justificativa

### Fase 4: Produção (se deployar sério)

- Adicionar metrics (Prometheus)
- Adicionar structured logging
- Implementar graceful shutdown
- Adicionar health checks avançados

---

## Testes de Segurança Recomendados

Antes de deploy em produção, executar:

### 1. Teste de DoS (OOM)

```bash
# Enviar request line gigante (deve rejeitar em 8KB)
python -c "print('GET /' + 'A'*10000 + ' HTTP/1.1\r\n\r\n')" | nc localhost 8080

# Enviar body gigante (deve rejeitar em 8KB)
dd if=/dev/zero bs=1M count=10 | curl -X POST --data-binary @- http://localhost:8080/api/validate
```

### 2. Teste de Path Traversal

```bash
# Todas devem retornar 400 ou 404
curl http://localhost:8080/../etc/passwd
curl http://localhost:8080/api/../../../etc/passwd
curl http://localhost:8080//etc/passwd
```

### 3. Teste de Method Injection

```bash
# Métodos não permitidos devem retornar 405
curl -X DELETE http://localhost:8080/health
curl -X TRACE http://localhost:8080/
curl -X "GET\r\nInjected: header" http://localhost:8080/
```

### 4. Teste de Timeout

```bash
# Enviar request lenta (deve fechar após 5s)
(echo -n "GET / HTTP/1.1\r\n"; sleep 10; echo "\r\n") | nc localhost 8080
```

### 5. Teste de CORS

```bash
# Deve incluir headers CORS apropriados
curl -H "Origin: https://example.com" -v http://localhost:8080/health
```

### 6. Teste de Resource Exhaustion

```bash
# Abrir muitas conexões simultâneas
for i in {1..1000}; do
  curl http://localhost:8080/health &
done
wait

# Verificar file descriptors não vazaram
lsof -p $(pgrep api) | wc -l
```

### 7. Teste de JSON Injection

```bash
# Escape sequences devem ser tratados
curl -X POST -H "Content-Type: application/json" \
  -d '{"cpf":"123\\\"injection\\\"456"}' \
  http://localhost:8080/api/validate
```

---

## Conclusão

Este projeto é **intencionalmente educacional**. Decisões foram tomadas priorizando **aprendizado** sobre **produção absoluta**.

Para um sistema de produção real, você adicionaria:

- Framework battle-tested (Axum, actix-web)
- Async runtime (tokio)
- Observabilidade completa
- Autenticação/Autorização
- Rate limiting
- CDN para assets

**Mas você não aprenderia como HTTP funciona por baixo.**

---

**Status:** Projeto em construção. Ver `01-*.md` a `04-*.md` para checklists.
