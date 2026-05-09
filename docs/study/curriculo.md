# Currículo de Engenharia de Software (Faculdade Pessoal)

> **Filosofia:** Matérias podem ser estudadas **em paralelo**. Você não precisa dominar Rust para fazer deploy. Você não precisa terminar Nand2Tetris para continuar o validador de CPF. Ganhe familiaridade em várias frentes simultaneamente.

---

## 📚 Fundamentos

### 1. Fundamentos de Hardware

Como a CPU executa código, hierarquia de memória (cache, RAM, disco), representação de dados.

- **Recursos:** Nand2Tetris, Ben Eater (YouTube), "Code" (Petzold)

### 2. Rust Básico

Sintaxe fundamental, tipos, control flow, structs, enums, pattern matching.

- **Recursos:** The Rust Book (Capítulos 1-8), Rustlings

### 3. Ownership e Memória

O sistema de ownership, borrowing, lifetimes, stack vs heap, smart pointers.

- **Recursos:** The Rust Book (Capítulos 4, 10, 15), Too Many Lists

### 4. Option<T> e Result<T>

Tipos fundamentais do Rust para lidar com valores opcionais e erros. Métodos úteis e patterns.

- **Recursos:** The Rust Book (Capítulo 6), Rust by Example, <https://doc.rust-lang.org/std/option/enum.Option.html>

### 5. Sistemas Operacionais (Básico)

Processos, syscalls, file descriptors, como o OS carrega programas.

- **Recursos:** Operating Systems: Three Easy Pieces (OSTEP)

---

## 🎓 Cursos e Livros Completos

### 6. The Rust Programming Language (The Book)

Livro oficial de Rust. Cobertura completa da linguagem.

- **Status:** Leitura progressiva (pode ser intercalada com projetos)

### 7. Comprehensive Rust (Google)

Curso de 4 dias criado pelo Google. Abordagem prática e abrangente.

- **Status:** A fazer em paralelo com projetos

---

## 🛠️ Projeto: Validador de CPF

### 8. Backend - TCP/HTTP Manual

Implementar servidor HTTP do zero usando apenas `std::net::TcpListener`.

- **Arquivos:** `01.2-tcp-listener.md`, `01.3-request-parser.md`, `01.4-response-builder.md`

### 9. Backend - Lógica de Validação

Implementar algoritmo de validação de CPF, routing, testes.

- **Arquivos:** `02-camada-logica.md`

### 10. Frontend - Vanilla TypeScript

Criar interface web sem frameworks. HTML5 + CSS3 + TypeScript puro.

- **Arquivos:** `03-camada-frontend.md`

### 11. Otimizações Avançadas

Thread pool manual, logs estruturados, métricas, zero-copy, async.

- **Arquivos:** `05-otimizacoes-avancadas.md`

---

## 🚀 Infraestrutura e Deploy

### 12. Deploy em VPS

SSH, systemd, configuração de servidor, segurança básica (firewall, fail2ban).

- **Arquivos:** `04-camada-deploy.md`

### 13. Docker e Containers

Dockerfile, multi-stage builds, `FROM scratch`, otimização de tamanho de imagem.

- **Arquivos:** `04-camada-deploy.md`, `docs/security/sandbox_rust_docker.md`

### 14. Observabilidade em Produção

Logs estruturados (JSON), métricas (Prometheus), correlation IDs, debugging sem shell.

- **Arquivos:** `docs/security/observabilidade-producao.md`

---

## 🔥 Rust Avançado

### 15. Unsafe Rust e Allocators

Blocos `unsafe`, FFI, implementar allocator customizado, entender undefined behavior.

- **Recursos:** Rustonomicon, Miri, "Rust for Rustaceans"

### 16. Concorrência e Async

Threads, Mutex, Arc, Atomics, async/await, tokio, futures.

- **Recursos:** "Rust Atomics and Locks" (Mara Bos), Jon Gjengset videos

---

## 📋 Notas de Uso

**Como usar este currículo:**

1. ✅ **Escolha 2-3 matérias para focar por semana** (não todas de uma vez)
2. ✅ **Alterne entre teoria e prática** (ex: ler The Book + continuar validador CPF)
3. ✅ **Deploy pode ser feito cedo** (mesmo sem dominar Rust, ganhe familiaridade)
4. ✅ **Hardware pode ser intercalado** (Nand2Tetris não bloqueia o resto)
5. ✅ **Documentação é viva** (marque progresso, adicione insights)

**Semana paralela de 09/05/2026 a 08/05/2027:**

- Segunda: The Rust Book + Projeto Validador CPF
- Terça: Comprehensive Rust + Projeto Validador CPF
- Quarta: Projeto Validador CPF + The Rust Book
- Quinta: Projeto Validador CPF + OSTEP
- Sexta: Docker e Deploy + Comprehensive Rust
- Sábado: Nand2Tetris + Projeto Validador CPF

**Depois:**

- Avaliar incluir observabilidade e Rust avançado
- Outras matérias

**Lembre-se:** Familiaridade se ganha com repetição distribuída, não com maestria sequencial.
