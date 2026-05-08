# Observabilidade em Produção: Debug sem Shell

## Introdução

Quando você adota o **Distroless**, você faz um pacto com o minimalismo: não há `bash`, não há `ls`, não há `curl` para testar a API internamente. Se algo quebra em produção, você não pode simplesmente dar um `docker exec` e "olhar ao redor".

A observabilidade deixa de ser um "nice to have" e se torna sua **única janela para a realidade** do sistema em execução.

Para um engenheiro raiz, isso não é limitação — é disciplina arquitetural.

---

## Os Três Pilares da Observabilidade

A observabilidade moderna se estrutura em três pilares complementares:

### 1. Logs (O Que Aconteceu)

Registros textuais de eventos discretos. São a narrativa do sistema.

### 2. Métricas (Quanto e Quando)

Valores numéricos agregados ao longo do tempo (latência, throughput, uso de CPU).

### 3. Traces (O Caminho da Requisição)

Rastreamento distribuído que mostra o fluxo de uma requisição através de múltiplos serviços.

> **Regra de ouro**: Logs dizem o "porquê", métricas dizem o "quanto", traces dizem o "onde".

---

## Logs Estruturados: JSON é a Lei

### O Problema com Logs de Texto

Logs tradicionais são strings livres:

```
[2026-05-08 14:23:45] User logged in successfully
[2026-05-08 14:23:46] ERROR: Payment failed
```

Isso é amadorismo. Você não consegue:

- Filtrar por usuário específico sem regex complexo
- Correlacionar eventos entre serviços
- Fazer agregações ou análises estatísticas

### A Solução: Logs Estruturados (JSON)

Cada evento é um objeto JSON com campos padronizados:

```json
{
  "timestamp": "2026-05-08T14:23:45Z",
  "level": "info",
  "message": "User logged in successfully",
  "user_id": "usr_42",
  "ip": "192.168.1.100",
  "correlation_id": "req_abc123"
}
```

```json
{
  "timestamp": "2026-05-08T14:23:46Z",
  "level": "error",
  "message": "Payment processing failed",
  "user_id": "usr_42",
  "payment_id": "pay_789",
  "correlation_id": "req_abc123",
  "error": "InsufficientFunds"
}
```

### Benefícios

- **Queryable**: Você pode pesquisar `user_id = "usr_42"` em todos os logs
- **Correlacionável**: O `correlation_id` conecta logs de diferentes serviços na mesma transação
- **Agregável**: Conte quantos erros de `InsufficientFunds` ocorreram na última hora

### Implementação em Rust

Use bibliotecas como `tracing` ou `slog`:

```rust
use tracing::{info, error};

info!(
    user_id = %user.id,
    ip = %request.ip(),
    "User logged in successfully"
);

error!(
    user_id = %user.id,
    payment_id = %payment.id,
    error = "InsufficientFunds",
    "Payment processing failed"
);
```

---

## Correlation IDs: O Fio de Ariadne

Em sistemas distribuídos, uma requisição pode passar por 5 serviços diferentes:

```
Frontend → API Gateway → Auth Service → Payment Service → Notification Service
```

Se o pagamento falha, como você rastreia o problema?

### A Solução: Correlation ID

Gere um UUID único na entrada da requisição e **propague-o por todos os serviços**:

1. O Frontend gera: `X-Correlation-ID: req_abc123`
2. Cada serviço registra logs com esse ID
3. Na investigação, você busca por `correlation_id = "req_abc123"` e vê **toda a jornada**

### Implementação

```rust
// Middleware que extrai ou gera o correlation_id
async fn correlation_middleware(
    req: Request,
    next: Next,
) -> Response {
    let correlation_id = req
        .headers()
        .get("X-Correlation-ID")
        .and_then(|v| v.to_str().ok())
        .unwrap_or_else(|| generate_uuid());

    // Injeta no contexto de tracing
    tracing::Span::current().record("correlation_id", correlation_id);

    next.run(req).await
}
```

---

## Métricas: O Pulso do Sistema

Logs são eventos discretos. Métricas são **agregações contínuas**.

### Tipos Essenciais

#### Counters (Contadores)

Valores que só sobem: requisições totais, erros totais.

```rust
metrics::increment_counter!("http_requests_total", "status" => "200");
```

#### Gauges (Medidores)

Valores que sobem e descem: conexões ativas, uso de memória.

```rust
metrics::gauge!("active_connections", active_count as f64);
```

#### Histograms (Histogramas)

Distribuição de valores: latência de requisições (p50, p95, p99).

```rust
let start = Instant::now();
// ... processa requisição
metrics::histogram!("request_duration_ms", start.elapsed().as_millis() as f64);
```

### Por que isso é crítico?

Você consegue detectar **degradação gradual** antes de virar incidente:

- Latência p95 subindo de 100ms para 500ms ao longo de 3 dias
- Taxa de erro passando de 0.1% para 2%
- Uso de memória crescendo linearmente (memory leak)

---

## Traces Distribuídos: OpenTelemetry

Traces mostram o **caminho completo** de uma requisição através dos serviços.

### Estrutura

Um **Trace** contém múltiplos **Spans** (segmentos):

```
Trace: req_abc123
├─ Span: HTTP GET /checkout [200ms]
   ├─ Span: Auth validation [20ms]
   ├─ Span: Database query [150ms]
   └─ Span: External API call [30ms]
```

Você vê instantaneamente que o gargalo está na query do banco.

### Implementação em Rust

Com `tracing-opentelemetry`:

```rust
use tracing::{instrument, info};

#[instrument]
async fn process_payment(user_id: &str, amount: f64) -> Result<(), PaymentError> {
    info!("Processing payment");

    // Span automático criado para essa função
    validate_user(user_id).await?;
    charge_card(amount).await?;

    Ok(())
}
```

Cada função anotada com `#[instrument]` cria um span automaticamente.

---

## Ephemeral Containers: O Paraquedas de Emergência

No Kubernetes, se você precisa investigar um pod Distroless **sem reconstruir a imagem**, use **ephemeral containers**.

### O Conceito

Você injeta temporariamente um container de debug **ao lado** do container da aplicação, compartilhando o namespace de rede e de processos.

### Como Usar

```bash
kubectl debug -it my-pod --image=busybox --target=my-container
```

Isso abre um shell `busybox` com acesso à rede do pod. Você pode:

- Fazer `wget` para testar conectividade
- Inspecionar `/proc` para ver processos
- Verificar variáveis de ambiente

### Limitações

- **Temporário**: O container de debug é destruído quando você sai
- **Não tem acesso ao filesystem** do container Distroless (por design)
- **Não substitui observabilidade**: É para investigação de rede e ambiente, não de lógica de aplicação

---

## Estratégias de Debug Remoto

### 1. Health Checks Verbosos

Exponha um endpoint `/health` com informações detalhadas:

```json
{
  "status": "healthy",
  "database": "connected",
  "cache": "connected",
  "uptime_seconds": 86400,
  "last_successful_payment": "2026-05-08T14:20:00Z"
}
```

### 2. Panic Hooks Customizados

Configure o Rust para registrar stack traces em logs estruturados:

```rust
std::panic::set_hook(Box::new(|panic_info| {
    error!(
        panic = %panic_info,
        "Application panicked"
    );
}));
```

### 3. Feature Flags de Debug

Tenha flags que ativam logs extras **em runtime** sem rebuild:

```rust
if env::var("DEBUG_SQL").is_ok() {
    info!(query = %sql, params = ?params, "Executing SQL");
}
```

---

## Stack Recomendada

### Para Logs

- **Biblioteca Rust**: `tracing` + `tracing-subscriber`
- **Agregador**: Loki, Elasticsearch, ou CloudWatch
- **Visualização**: Grafana, Kibana

### Para Métricas

- **Biblioteca Rust**: `metrics` + `metrics-exporter-prometheus`
- **Coleta**: Prometheus
- **Visualização**: Grafana

### Para Traces

- **Biblioteca Rust**: `tracing-opentelemetry`
- **Backend**: Jaeger, Tempo, ou Honeycomb
- **Visualização**: Jaeger UI, Grafana

---

## O Custo da Observabilidade

Observabilidade não é gratuita:

### 1. Overhead de Performance

Cada log e métrica consome CPU e I/O. Logs excessivos podem aumentar latência em 5-10%.

**Solução**: Use sampling para traces (grave apenas 1% das requisições normais, 100% das com erro).

### 2. Volume de Dados

Logs estruturados em JSON ocupam mais espaço que texto simples. Um sistema de médio porte pode gerar **100GB/dia** de logs.

**Solução**: Retenção inteligente (7 dias de logs completos, 90 dias de métricas agregadas).

### 3. Complexidade Operacional

Você precisa gerenciar o stack de observabilidade (Prometheus, Loki, Jaeger).

**Solução**: Managed services (Grafana Cloud, Datadog) ou observabilidade nativa da cloud (AWS CloudWatch).

---

## Conclusão

No ambiente Distroless, observabilidade não é opcional — é a **única forma de ver dentro da caixa preta**.

A diferença entre um sistema amador e um sistema de produção real é que o amador espera o erro acontecer para "dar um `ssh` e olhar os logs". O engenheiro raiz **já tem os logs estruturados, métricas em tempo real e traces distribuídos** antes do primeiro deploy.

Quando algo quebra em produção (e vai quebrar), você não quer estar tentando adicionar logs. Você quer abrir o Grafana e **já saber exatamente onde está o problema**.
