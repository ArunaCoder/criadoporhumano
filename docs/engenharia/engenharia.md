# O Caminho para Engenheiro de Software

## Introdução

Para um autodidata disciplinado, estudando **4 horas por dia**, o tempo para se tornar um **engenheiro** (no sentido de projetar sistemas com rigor e previsibilidade) gira em torno de **2 a 3 anos**.

Este documento mapeia as fases desse caminho e conecta cada etapa ao **seu projeto atual**.

---

## As Três Fases

### 1. Fase da Escuridão (0 - 6 meses)

**Objetivo:** Entender o hardware e a base computacional.

Aqui você não constrói nada "útil". Você foca no que acontece **abaixo** do código.

#### O que estudar

- **Arquitetura de computadores**: Como a CPU executa instruções
- **Memória**: Stack vs Heap, alocação, desalocação
- **Sistemas de numeração**: Binário, hexadecimal, representação de dados
- **Lógica de programação**: Fluxo de controle, recursão, invariantes

#### O custo emocional

Frustração extrema. Você verá seus amigos fazendo sites coloridos com React enquanto você está sofrendo para entender **por que** um ponteiro em C ou uma referência em Rust funciona daquele jeito.

#### Como este projeto se encaixa

**Status atual:** Se você está começando este monorepo, provavelmente já passou dessa fase.

**Evidências no projeto:**

- Você escolheu **Rust**, não JavaScript puro
- Você entende que `ownership` existe por causa de Stack/Heap
- Você sabe por que `FROM scratch` (containers sem OS) é possível

**Se ainda está nesta fase:**

- Estude o projeto [`01-validador-cpf-basico`](01-validador-cpf-basico/00-visao-geral.md)
- Foque em entender **cada linha** do TCP listener manual
- Desenhe no papel como bytes viajam da rede até a função

---

### 2. Fase do Rigor (6 - 18 meses)

**Objetivo:** Construir com restrições. Sem frameworks, apenas fundamentos.

Aqui você começa a construir, mas **rejeitando** abstrações prontas.

#### O que estudar

- **Algoritmos e Estruturas de Dados**: Não para passar em entrevista, mas para saber **quando** usar um `HashMap` vs um `BTreeMap`
- **Redes**: HTTP/TCP/UDP no detalhe (handshake, headers, estados)
- **Rust**: Ownership, lifetimes, concorrência (Mutex, Arc, Atomics)
- **Parsing manual**: Como transformar bytes em estruturas de dados

#### O projeto obrigatório

**Criar um servidor HTTP do zero, usando apenas sockets.**

Se você não entender o handshake do TCP, você não é um engenheiro de backend — é apenas um usuário de bibliotecas.

#### Como este projeto se encaixa

**Status atual:** Você está **nesta fase agora**.

**Evidências no projeto:**

- ✅ Servidor HTTP manual ([`01-validador-cpf-basico/01.2-tcp-listener.md`](01-validador-cpf-basico/01.2-tcp-listener.md))
- ✅ Parser HTTP manual ([`01-validador-cpf-basico/01.3-request-parser.md`](01-validador-cpf-basico/01.3-request-parser.md))
- ✅ Response builder manual ([`01-validador-cpf-basico/01.4-response-builder.md`](01-validador-cpf-basico/01.4-response-builder.md))
- ✅ Validador de CPF sem bibliotecas externas ([`backend/shared/src/lib.rs`](../backend/shared/src/lib.rs))
- ⚠️ Thread pool está documentado mas não implementado ([`01-validador-cpf-basico/05-otimizacoes-avancadas.md`](01-validador-cpf-basico/05-otimizacoes-avancadas.md))

**Tarefas desta fase:**

- [ ] Implementar thread pool manual (sem `tokio`)
- [ ] Adicionar observabilidade (logs estruturados) sem frameworks
- [ ] Criar parser de JSON do zero (entender gramáticas)
- [ ] Implementar cache em memória com `Mutex<HashMap>`

**Conceitos críticos a dominar:**

- Por que `Connection: close` previne resource exhaustion
- Como timeout previne slowloris attack
- Por que prepared statements previnem SQL injection (quando adicionar DB)

---

### 3. Fase do Sistema (18 - 30+ meses)

**Objetivo:** Sair do código e ir para o contexto.

Aqui você para de pensar em "funções" e começa a pensar em **sistemas distribuídos, falhas, segurança e escala**.

#### O que estudar

- **Bancos de dados**: Índices, níveis de isolamento (READ COMMITTED vs SERIALIZABLE), ACID, TOCTOU em queries
- **Infraestrutura**: Docker, namespaces, cgroups, syscalls, filesystem
- **Segurança**: TOCTOU, IDOR, Sandboxing, Defense in Depth
- **Observabilidade**: Logs estruturados, métricas, traces distribuídos
- **Trade-offs**: CAP theorem, latência vs throughput, consistency vs availability

#### O custo: Maturidade

Você começa a dizer **"não"** para soluções complexas. Você prefere um monólito bem estruturado com SQL puro (`sqlx`) a um emaranhado de microserviços que ninguém entende.

#### Como este projeto se encaixa

**Status atual:** Você está **entrando** nesta fase.

**Evidências no projeto:**

- ✅ Documentação de segurança completa:
  - [checklist-desenvolvimento-seguro.md](security/checklist-desenvolvimento-seguro.md) — Guia de campo por tipo de código
  - [logica-negocio.md](security/logica-negocio.md) — IDOR, TOCTOU, DoS lógico
  - [toc-tou.md](security/toc-tou.md) — Race conditions e atomicidade
  - [observabilidade-producao.md](security/observabilidade-producao.md) — Logs, métricas, traces
  - [distroless.md](security/distroless.md) — Containers minimalistas
  - [sandbox_rust_docker.md](security/sandbox_rust_docker.md) — Isolamento com Docker
- ✅ Deploy com `FROM scratch` ([`01-validador-cpf-basico/04-camada-deploy.md`](01-validador-cpf-basico/04-camada-deploy.md))
- ✅ Entendimento de trade-offs (debugabilidade vs segurança)
- ⚠️ Falta banco de dados real (SQLite planejado)
- ⚠️ Falta autenticação/autorização implementada

**Tarefas desta fase:**

- [ ] Adicionar SQLite com `sqlx` (sem ORM)
- [ ] Implementar autenticação (Argon2, timing-safe comparison)
- [ ] Criar sistema de autorização (resource-level permissions)
- [ ] Simular ataques (SQL injection, IDOR, race conditions)
- [ ] Implementar observabilidade completa (Prometheus + Grafana)
- [ ] Fazer load testing (encontrar o ponto de falha)
- [ ] Documentar post-mortem de cada falha encontrada

**Conceitos críticos a dominar:**

- Por que ORM esconde problemas (N+1 queries, memory bloat)
- Como race conditions em DB causam double-spending
- Por que logs estruturados são obrigatórios em `FROM scratch`
- Quando escolher Alpine vs Distroless vs `FROM scratch`

---

## O que Acelera ou Atrasa esse Processo?

### ✅ O que acelera

1. **Ignorar "hypes"**: Não perca 1 hora estudando "a nova funcionalidade do Next.js". Gaste essa hora lendo a documentação do `tokio` em Rust ou entendendo como o Nginx faz balanceamento de carga.

2. **Quebrar o sistema**: Código que nunca falha não ensina. Force race conditions, estoure limites de memória, simule network partition.

3. **Ler código de produção**: Estude o código-fonte do SQLite, do Redis, do Nginx. Veja como engenheiros reais lidam com edge cases.

4. **Documentar falhas**: Cada erro encontrado vira um documento. Este projeto tem [`security/`](security/) cheio de post-mortems conceituais.

5. **Restrições forçadas**: Proibir frameworks não é masoquismo, é pedagogia. Você só entende HTTP depois de parsear bytes crus.

### ❌ O que atrasa

1. **Tutorial Hell**: Se você só copia o que o instrutor faz no vídeo, você não está aprendendo engenharia — está aprendendo adestramento.

2. **Framework First**: Se sua primeira linha de código é `npm install express`, você nunca vai entender o que o Express faz por você.

3. **Falta de rigor**: "Funciona na minha máquina" não é engenharia. Engenharia é: "Funciona sob essas condições, com esses limites, e falha de forma controlada quando excedidos".

4. **Medo de C/Rust**: Se você evita linguagens "difíceis", você nunca vai entender memória. E se não entende memória, não entende performance.

5. **Não ler documentação**: Stack Overflow é para referência rápida. Engenharia se aprende na RFC do HTTP, no manual do `tokio`, no código do Kernel do Linux.

---

## Por que esse Tempo?

Porque engenharia exige **massa crítica de erros**.

- Você precisa ver um banco de dados travar em um **deadlock** para entender por que a ordem das suas queries importa
- Você precisa ter um sistema **invadido** (em ambiente controlado) para entender por que o Distroless não é frescura, é necessidade
- Você precisa ver um servidor **cair por OOM** para entender por que limites de payload existem
- Você precisa depurar uma **race condition** às 3h da manhã para nunca mais esquecer de usar `Mutex`

**Não existe atalho.** Você pode copiar um padrão, mas não pode copiar a experiência de ter sido **humilhado por um bug sutil** e depois entender o porquê.

---

## Métricas de Progresso

### Como saber se você está avançando?

#### Fase 1 completa quando:

- [ ] Você consegue desenhar o caminho de um byte desde a rede até a RAM
- [ ] Você explica ownership em Rust sem consultar docs
- [ ] Você sabe por que `malloc`/`free` existem em C

#### Fase 2 completa quando:

- [ ] Você cria um servidor HTTP que passa em testes de segurança básicos
- [ ] Você lê RFCs (HTTP, TCP) e entende a notação
- [ ] Você debugga problemas de rede com `tcpdump`/`wireshark`
- [ ] Você implementa estruturas de dados (HashMap, LinkedList) do zero

#### Fase 3 completa quando:

- [ ] Você projeta sistemas que **falham de forma controlada**
- [ ] Você escreve post-mortems de incidentes (reais ou simulados)
- [ ] Você diz "não" para complexidade desnecessária com argumentos técnicos
- [ ] Você entende os trade-offs de **todas** as suas decisões arquiteturais
- [ ] Você consegue estimar latência/throughput antes de implementar

---

## Roadmap do Projeto Atual

### ✅ Completo

- [x] Servidor HTTP manual (Fase 2)
- [x] Parser HTTP manual (Fase 2)
- [x] Validação de CPF sem libs (Fase 2)
- [x] Deploy com `FROM scratch` (Fase 3)
- [x] Documentação de segurança (Fase 3)

### 🚧 Em Andamento (Fase 2 → Fase 3)

- [ ] Thread pool manual
- [ ] Logs estruturados (JSON) sem frameworks
- [ ] Métricas básicas (contadores atômicos)
- [ ] Health checks verbose

### 📋 Próximo (Fase 3)

- [ ] Adicionar SQLite com `sqlx`
  - [ ] Migrations manuais
  - [ ] Prepared statements
  - [ ] Transações atômicas
  - [ ] Simulação de race conditions
- [ ] Sistema de autenticação
  - [ ] Hash de senhas (Argon2)
  - [ ] Tokens JWT (manual, sem libs)
  - [ ] Timing-safe comparison
- [ ] Sistema de autorização
  - [ ] Resource-level permissions
  - [ ] IDOR prevention
  - [ ] Audit logs
- [ ] Observabilidade completa
  - [ ] Prometheus exporter
  - [ ] Correlation IDs
  - [ ] Traces distribuídos (OpenTelemetry)
- [ ] Testes de invasão
  - [ ] SQL injection attempts
  - [ ] Path traversal attempts
  - [ ] Race condition exploits
  - [ ] DoS simulation
- [ ] Load testing
  - [ ] Encontrar ponto de quebra
  - [ ] Otimizar gargalos
  - [ ] Documentar limites

---

## O Veredito

**Em 1 ano** você será um bom **desenvolvedor**.

**Em 3 anos** de estudo disciplinado (4h/dia focadas em fundamentos), você terá a base necessária para se chamar de **engenheiro** e sustentar esse título com código sólido.

### Onde você está agora?

Com base neste projeto:

- ✅ **Fase 1 completa**: Você entende memória, ownership, fundamentos
- 🚧 **Fase 2 em progresso**: ~70% completa (falta concorrência real, parsing complexo)
- 🌱 **Fase 3 iniciando**: Fundamentos de segurança documentados, falta implementação real

**Estimativa:** Se você mantiver o ritmo, completará Fase 2 em **2-3 meses** e entrará na Fase 3 completa em **6-9 meses**.

---

## Recursos Relacionados

### Documentação interna

- [AGENTS.md](../AGENTS.md) — Diretrizes para IA (inclui sistema de FASE)
- [01-validador-cpf-basico/](01-validador-cpf-basico/) — Projeto guiado (Fase 2)
- [security/](security/) — Guias de segurança (Fase 3)

### Leitura recomendada

- **Livros**: "Designing Data-Intensive Applications" (Martin Kleppmann)
- **RFCs**: RFC 7230 (HTTP/1.1), RFC 793 (TCP)
- **Código-fonte**: SQLite, Redis, Nginx
- **Blog**: Julia Evans (networking), Brandon Smith (Rust systems programming)

---

## Conclusão

Engenharia de software não é sobre **saber todas as bibliotecas**. É sobre:

1. **Entender os fundamentos** (Fase 1)
2. **Construir sem abstrações** (Fase 2)
3. **Projetar sistemas que falham gracefully** (Fase 3)

Este projeto é seu **laboratório**. Cada linha de código sem framework é uma repetição de academia mental. Cada falha simulada é uma cicatriz que te torna mais forte.

**O atalho é não ter atalho.** Continue quebrando coisas.
