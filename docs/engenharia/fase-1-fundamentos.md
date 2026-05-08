# Fase 1: Aprendendo os Fundamentos

## Para quem é este documento?

Se você:

- Está começando do zero em programação de sistemas
- Tentou pular direto para frameworks e sentiu que falta algo
- Não entende **por que** o código funciona, apenas que funciona
- Quer entender o que acontece **abaixo** do código

**Este documento é seu ponto de partida.**

---

## O Problema de Pular esta Fase

### Sintomas de quem pulou:

- ❌ Você não consegue explicar a diferença entre Stack e Heap
- ❌ Você acha que "memória é só um detalhe de implementação"
- ❌ Você não entende por que Rust tem `ownership` ou C tem ponteiros
- ❌ Você copia código que funciona mas não sabe **por que** funciona
- ❌ Você tem medo de debugar problemas de performance ou memory leaks
- ❌ Você acha que "o framework resolve isso" para tudo

### O custo de pular:

Você ficará **eternamente dependente de abstrações**. Quando o framework falhar (e vai falhar), você não terá ferramentas mentais para resolver o problema.

> **Analogia:** É como dirigir um carro sem saber que existe motor, freios e combustível. Funciona até quebrar.

---

## 🦀 Decisão: 100% Rust (com C apenas como referência opcional)

### A Decisão Tomada Neste Documento

**Este guia assume que você vai focar 100% em Rust, SEM aprender C como linguagem.**

**C aparece apenas como ferramenta pedagógica opcional:** Se você travar em ownership/borrowing, pode ler sobre ponteiros em C por 1-2 dias para entender o problema "sem rede de segurança".

### ✅ Vantagens desta Abordagem

- ✅ **Mais rápido**: 4-5 meses até Fase 2 (vs 6-8 meses aprendendo C completo)
- ✅ **Mais moderno**: Ferramental excelente (Cargo, rustup, Clippy, rust-analyzer)
- ✅ **Mais seguro**: Compiler te ensina desde o início
- ✅ **Mais motivador**: Você constrói sistemas reais sem sofrer com segfaults
- ✅ **Foco**: Especialização em Rust desde o dia 1
- ✅ **Comunidade ativa**: Discord Rust, r/rust, users.rust-lang.org

### ⚠️ Desvantagens e Como Mitigar

- ❌ **Curva inicial íngreme** (ownership + borrowing + lifetimes de uma vez)
  - 🛠️ **Mitigação**: Rustlings, Too Many Lists, Jon Gjengset videos

- ❌ **Recursos clássicos usam C** (K&R, CS:APP, OSTEP)
  - 🛠️ **Mitigação**: Leia os conceitos, ignore os códigos C, implemente em Rust

- ❌ **Você pode não entender "por que" Rust é restritivo**
  - 🛠️ **Mitigação**: Quando travar, leia 1 capítulo sobre ponteiros em C (Beej's Guide)

- ❌ **Difícil ler código C legado** (Linux kernel, Redis, SQLite)
  - 🛠️ **Mitigação**: Se precisar futuramente, aprenda C em 2-3 semanas (você já saberá os conceitos)

### Como C Aparece Neste Documento

- **Seções gerais** (Hardware, OS): Independentes de linguagem
- **Código**: 100% Rust como principal
- **Recursos**: Livros C marcados como "📖 Opcional para conceitos"
- **Projetos**: Todos implementados em Rust
- **Comparações**: C mencionado apenas para explicar "o que Rust previne"

### Quando Considerar Estudar C

**Estude C (1-2 dias) SE:**

- Você travou em ownership/borrowing e quer ver o problema "cru"
- Você precisa ler código C legado (contribuir para Linux, Redis, etc.)
- Você quer entender FFI (Foreign Function Interface) profundamente

**NÃO precisa estudar C SE:**

- Seu objetivo é construir sistemas modernos em Rust
- Você está confortável aprendendo com o borrow checker
- Você tem acesso a comunidade/mentores Rust

---

## O que Você Precisa Aprender

### 1. Como o Computador Funciona (Hardware)

**Conceitos:**

- Como a CPU executa instruções (fetch-decode-execute)
- Registradores, cache, RAM, disco (hierarquia de memória)
- Binário e hexadecimal (representação de dados)
- Como números inteiros e floats são armazenados

**Por que importa:**

- Você entende por que cache misses são caros
- Você entende por que `i32` vs `i64` afeta performance
- Você sabe por que alignment importa em structs

**Recursos:**

📚 **Livros:**

- **"Code: The Hidden Language of Computer Hardware and Software"** (Charles Petzold)
  - ⭐⭐⭐⭐⭐ Melhor livro para iniciantes
  - Explica desde circuitos até assembly de forma acessível
  - Não precisa de background técnico

- **"Computer Systems: A Programmer's Perspective"** (Bryant & O'Hallaron)
  - ⭐⭐⭐⭐⭐ Bíblia da área (conhecido como "CS:APP")
  - Usado em cursos de universidades top (CMU, MIT)
  - Cobre desde bits até sistemas operacionais
  - Projeto prático: implementar um shell Unix

🌐 **Online:**

- **Nand2Tetris** (https://www.nand2tetris.org/)
  - Curso GRATUITO que constrói um computador do zero
  - Começa com portas lógicas, termina com Tetris
  - Projeto hands-on mais completo que existe

- **Ben Eater** (YouTube: @BenEater)
  - Constrói computadores 8-bit com breadboards
  - Visualização física de como CPU funciona
  - Excelente para entender clock, registradores, ALU

---

### 2. Memória: Stack vs Heap

**Conceitos:**

- Como o programa usa memória (stack, heap, data, code)
- Allocation (malloc/new) vs stack frames
- Por que memory leaks acontecem
- Ponteiros e referências

**Por que importa:**

- Você entende por que Rust tem `Box<T>` e `&T`
- Você sabe quando usar heap e quando usar stack
- Você consegue debugar segmentation faults

**Recursos:**

**Recursos:**

📚 **Livros (Foco Principal):**

- **"The Rust Programming Language"** (Steve Klabnik & Carol Nichols) 🦀
  - ⭐⭐⭐⭐⭐ GRATUITO online (https://doc.rust-lang.org/book/)
  - Conhecido como "The Book"
  - Ensina ownership, borrowing, lifetimes desde o zero
  - **Capítulos críticos**: 4 (Ownership), 10 (Lifetimes), 15 (Smart Pointers)
  - **COMECE AQUI**

- **"Rust for Rustaceans"** (Jon Gjengset) 🦀
  - ⭐⭐⭐⭐⭐ Para quem quer dominar Rust profundamente
  - Explica o "porquê" de cada design decision
  - Capítulos sobre unsafe, FFI, performance

📖 **Opcional (apenas para conceitos, SE travar em ownership):**

- **"The C Programming Language"** (Kernighan & Ritchie)
  - ⭐⭐⭐⭐⭐ Clássico (conhecido como "K&R")
  - Use apenas Capítulo 5 (Pointers) SE travar no borrow checker
  - Leia 1-2 dias, depois volte para Rust

- **"Understanding and Using C Pointers"** (Richard Reese)
  - ⭐⭐⭐⭐ Focado 100% em ponteiros
  - Diagramas visuais excelentes
  - Use apenas se Rust não fizer sentido ainda

🌐 **Online (Foco Principal):**

- **"Rust by Example"** (https://doc.rust-lang.org/rust-by-example/) 🦀
  - ⭐⭐⭐⭐⭐ GRATUITO, aprenda fazendo
  - Cobre ownership, borrowing, smart pointers
  - **RECURSO OBRIGATÓRIO**

- **"Too Many Lists"** (https://rust-unofficial.github.io/too-many-lists/) 🦀
  - ⭐⭐⭐⭐⭐ GRATUITO, implementa LinkedList em Rust
  - Explica `Box`, `Rc`, `RefCell`, unsafe
  - **Melhor tutorial de ownership/ponteiros que existe**

- **Jon Gjengset** (YouTube: @jonhoo) 🦀
  - ⭐⭐⭐⭐⭐ Live coding de projetos Rust reais
  - "Crust of Rust" series sobre tópicos intermediários
  - Explica o "porquê" de cada decisão

📖 **Opcional (apenas conceitos):**

- **Beej's Guide to C Programming** (https://beej.us/guide/bgc/)
  - GRATUITO, bem-humorado
  - Use apenas Capítulo sobre ponteiros SE travar

- **Pointer Basics (Stanford)** (http://cslibrary.stanford.edu/102/)
  - GRATUITO, 18 páginas, diagramas visuais
  - Útil para ver conceitos "crus" antes do borrow checker abstrair

---

### 3. Como o Código Vira Executável

**Conceitos:**

- Compilação (source → assembly → machine code)
- Linking (static vs dynamic)
- Binários e executáveis (ELF, PE)
- Como o OS carrega um programa na memória

**Por que importa:**

- Você entende por que Rust compila lento (LLVM otimizações)
- Você sabe por que binários estáticos são grandes
- Você consegue debugar "symbol not found" errors

**Recursos:**

📚 **Livros:**

- **"Linkers and Loaders"** (John Levine)
  - ⭐⭐⭐⭐ Focado em linking
  - Explica o que acontece depois de `cargo build`

🌐 **Online:**

- **Compiler Explorer** (https://godbolt.org/)
  - Veja seu código Rust/C virar assembly em tempo real
  - Compare otimizações (`-O0` vs `-O3`)
  - FERRAMENTA OBRIGATÓRIA

- **"What Every Programmer Should Know About Memory"** (Ulrich Drepper)
  - Paper técnico (GRATUITO PDF)
  - Explica cache, prefetch, NUMA
  - Avançado mas essencial

---

### 4. Sistemas Operacionais (Básico)

**Conceitos:**

- Processos vs threads
- Syscalls (o que realmente acontece em `File::open()`)
- File descriptors
- Como o scheduler funciona

**Por que importa:**

- Você entende por que `spawn` em Rust cria threads
- Você sabe por que `async` economiza memória
- Você consegue debugar "too many open files"

**Recursos:**

📚 **Livros:**

- **"Operating Systems: Three Easy Pieces"** (Remzi & Andrea Arpaci-Dusseau)
  - ⭐⭐⭐⭐⭐ GRATUITO online (http://pages.cs.wisc.edu/~remzi/OSTEP/)
  - Explica processos, memória virtual, concorrência
  - Projetos práticos em C
  - Usado em cursos universitários

- **"The Linux Programming Interface"** (Michael Kerrisk)
  - ⭐⭐⭐⭐⭐ Referência definitiva de syscalls Linux
  - 1500+ páginas, mas cada capítulo é independente
  - Consulte quando precisar entender um syscall específico

🌐 **Online:**

- **"Writing an OS in Rust"** (Philipp Oppermann)
  - https://os.phil-opp.com/
  - GRATUITO, atualizado, excelente
  - Constrói um OS do zero em Rust
  - Ensina bootloader, paging, interrupts

---

## Roadmap de Estudo (6 meses, 4h/dia)

### Mês 1-2: Fundamentos de Hardware

**Semanas 1-4:**

- [ ] Leia "Code" (Charles Petzold) — 1 capítulo por dia
- [ ] Assista Ben Eater (1 vídeo por dia sobre 8-bit CPU)
- [ ] Faça Nand2Tetris (Projetos 1-6: hardware)

**Semanas 5-8:**

- [ ] Leia "Computer Systems: A Programmer's Perspective" (Capítulos 1-3)
- [ ] Experimente no Compiler Explorer: veja código C **ou Rust** virar assembly
- [ ] **Rota C**: Escreva programas simples em C (apenas stdio.h)
- [ ] **Rota Rust**: Comece "The Rust Book" (Capítulos 1-3)

**Checkpoint:** Você consegue explicar como `int x = 5;` (C) ou `let x: i32 = 5;` (Rust) vira instruções de CPU?

---

### Mês 3-4: Memória e Ownership

**Semanas 9-12:**

- [ ] Leia "The Rust Book" (Capítulos 4, 10, 15) — Ownership, Lifetimes, Smart Pointers
- [ ] Faça todos os exercícios do Rustlings (https://github.com/rust-lang/rustlings)
- [ ] Leia "Too Many Lists" (implementa LinkedList em Rust)
- [ ] Implemente estruturas de dados: Vec, HashMap, LinkedList do zero
- [ ] 📖 **Opcional**: Se travar, leia Beej's Guide (Capítulo sobre ponteiros) por 1-2 dias

**Semanas 13-16:**

- [ ] Leia "Rust for Rustaceans" (Capítulos 1-5)
- [ ] Implemente um allocator simples (unsafe Rust)
- [ ] Use Miri para detectar undefined behavior
- [ ] Assista Jon Gjengset: "Crust of Rust" series (ownership, lifetimes, iterators)
- [ ] 📖 **Opcional**: Leia sobre como `malloc`/`free` funcionam em C (apenas conceito)

**Checkpoint:** Você consegue desenhar no papel como `Box<T>`, `Rc<T>` e `&T` funcionam? Você explica borrow checker sem consultar docs?

---

### Mês 5-6: Sistemas Operacionais

**Semanas 17-20:**

- [ ] Leia "Operating Systems: Three Easy Pieces" (Capítulos 1-14)
- [ ] Implemente um shell Unix simples em Rust (use `std::process::Command`)
- [ ] Experimente com strace: veja syscalls em tempo real
- [ ] 📖 **Opcional**: Leia código C de exemplo de fork/exec (OSTEP) apenas para comparar

**Semanas 21-24:**

- [ ] Leia "Writing an OS in Rust" (até multiprocessing)
- [ ] Estude file descriptors (open, read, write, close)
- [ ] Implemente um servidor TCP echo em Rust (`std::net::TcpListener`)
- [ ] Refaça com async (tokio): veja diferença de 1 thread vs N threads
- [ ] Use `ltrace`/`strace` para ver syscalls do seu programa Rust

**Checkpoint:** Você consegue explicar o que acontece quando você roda `./programa`? Você sabe quantos syscalls um `println!` faz?

---

## Projetos Práticos Obrigatórios

### Projeto 1: Implementar um Allocator

#### Versão C

```c
void* my_malloc(size_t size);
void my_free(void* ptr);
```

#### 🦀 Versão Rust

```rust
use std::alloc::{GlobalAlloc, Layout};

struct MyAllocator;

unsafe impl GlobalAlloc for MyAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        // Implementar
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        // Implementar
    }
}
```

**O que você aprende:**

- Como heap funciona
- Fragmentação de memória
- Por que `free()` precisa saber o tamanho
- 🦀 **Em Rust**: Por que `Box` precisa de `Drop`, como `unsafe` funciona

**Recursos:**

- C: https://arjunsreedharan.org/post/148675821737/memory-allocators-101-write-a-simple-memory
- 🦀 Rust: https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html

---

### Projeto 2: Implementar Estruturas de Dados

#### Versão C

```c
typedef struct Node {
    int data;
    struct Node* next;
} Node;

void list_push(Node** head, int value);
int list_pop(Node** head);
```

#### 🦀 Versão Rust

```rust
struct Node {
    data: i32,
    next: Option<Box<Node>>,
}

struct List {
    head: Option<Box<Node>>,
}

impl List {
    fn push(&mut self, value: i32) { /* implementar */ }
    fn pop(&mut self) -> Option<i32> { /* implementar */ }
}
```

**O que você aprende:**

- Ponteiros duplos (`**`) vs `Option<Box<T>>`
- Por que ownership em Rust é mais seguro
- Quando usar heap vs stack
- 🦀 **Leitura obrigatória**: "Too Many Lists" (https://rust-unofficial.github.io/too-many-lists/)

---

### Projeto 3: Shell Unix Básico

#### Versão C

```c
// Ler comando
// Fork processo
// Exec comando
// Wait filho terminar
```

#### 🦀 Versão Rust

```rust
use std::process::Command;

loop {
    let input = read_line();
    let parts: Vec<&str> = input.split_whitespace().collect();

    if let Some(cmd) = parts.first() {
        Command::new(cmd)
            .args(&parts[1..])
            .status()
            .expect("Failed to execute");
    }
}
```

**O que você aprende:**

- Processos e syscalls
- File descriptors (stdin, stdout, stderr)
- Por que pipes (`|`) existem
- 🦀 **Em Rust**: Como `Command` abstrai `fork`/`exec`, mas ainda é transparente

**Recursos:**

- C: https://brennan.io/2015/01/16/write-a-shell-in-c/
- 🦀 Rust: https://doc.rust-lang.org/std/process/struct.Command.html

---

### Projeto 4: Servidor TCP Echo

#### Versão C

```c
int server_fd = socket(AF_INET, SOCK_STREAM, 0);
bind(server_fd, ...);
listen(server_fd, 10);

while (1) {
    int client = accept(server_fd, ...);
    // Ler dados
    // Ecoar de volta
    close(client);
}
```

#### 🦀 Versão Rust

```rust
use std::net::TcpListener;
use std::io::{Read, Write};

let listener = TcpListener::bind("127.0.0.1:8080")?;

for stream in listener.incoming() {
    let mut stream = stream?;
    let mut buffer = [0; 1024];

    let n = stream.read(&mut buffer)?;
    stream.write_all(&buffer[..n])?;
}
```

**O que você aprende:**

- TCP handshake
- Blocking I/O
- Por que `async` existe (compare com a dor do blocking)
- 🦀 **Em Rust**: Como `Result<T, E>` força error handling, RAII fecha sockets automaticamente

**Depois:**

- Refaça com threads (1 thread por conexão)
- 🦀 Refaça com `tokio` (async): veja como 1 thread serve 10k conexões

---

## Conexão com Este Projeto

### Se você ainda está na Fase 1:

1. **NÃO comece pelo projeto principal ainda**
   - Faça os projetos em C primeiro
   - Entenda ponteiros antes de ownership

2. **Use o projeto como "objetivo final"**
   - Quando terminar Fase 1, você estará pronto para [`01-validador-cpf-basico`](../01-validador-cpf-basico/00-visao-geral.md)
   - Tudo parecerá mais fácil porque você saberá o "porquê"

3. **Leia o código do projeto como estudo**
   - Abra [`backend/api/src/main.rs`](../../backend/api/src/main.rs)
   - Tente entender o que cada linha faz
   - Pesquise o que não entender (mas não copie ainda)

---

## Recursos Adicionais

### 📚 Livros Clássicos (Todo Engenheiro Deveria Ler)

1. **"The C Programming Language"** (K&R) — Fundação
2. **"Computer Systems: A Programmer's Perspective"** — Essencial
3. **"Operating Systems: Three Easy Pieces"** — GRATUITO e excelente
4. **"Code"** (Petzold) — Para iniciantes absolutos
5. **"The Art of Computer Programming"** (Knuth) — Avançado, referência

### 🌐 Blogs Obrigatórios

- **Julia Evans** (https://jvns.ca/)
  - Zines sobre networking, syscalls, debugging
  - Linguagem acessível, diagramas excelentes

- **Eli Bendersky** (https://eli.thegreenplace.net/)
  - Posts sobre compiladores, assembly, C
  - Rigor técnico sem ser intimidador

- **Beej's Guides** (https://beej.us/guide/)
  - C Programming, Network Programming, Git
  - GRATUITO, bem-humorado, prático

- **Low Level Learning** (YouTube: @LowLevelLearning)
  - Vídeos sobre C, assembly, sistemas
  - Projetos práticos guiados

### 🛠️ Ferramentas que Você Deve Dominar

- **GDB** — Debugger de C/Rust
- **Valgrind** — Detecta memory leaks
- **strace** — Vê syscalls em tempo real
- **Compiler Explorer** (godbolt.org) — Vê assembly
- **objdump / nm** — Inspeciona binários

---

## Sinais de Progresso

### Você completou Fase 1 quando:

- [ ] Você explica ownership/borrowing/lifetimes de forma clara para alguém
- [ ] Você escreve código Rust sem lutar contra o borrow checker
- [ ] Você sabe quantos syscalls um `println!("Hello")` faz
- [ ] Você implementou allocator básico (unsafe Rust)
- [ ] Você criou um shell Unix em Rust que executa comandos
- [ ] Você lê assembly (Rust compilado) e entende o que está acontecendo
- [ ] Você debugga com LLDB/GDB sem copiar do Stack Overflow
- [ ] Você consegue ler código C e entender o conceito (mesmo sem escrever C)
- [ ] Você explica **por que** Rust previne data races e use-after-free

---

## Armadilhas Comuns

### ❌ Erro 1: Ignorar a Frustração do Borrow Checker

**Problema:** Você luta contra o borrow checker e desiste.

**Solução:** A frustração é **parte do processo**. Quando o compiler rejeita seu código, ele está te ensinando. Se travar muito, leia 1-2 capítulos sobre ponteiros em C (Beej's Guide) para ver o problema "sem rede". Depois volte para Rust e veja como ownership resolve o problema.

### ❌ Erro 2: Só Ler, Não Fazer

**Problema:** Você lê livros mas não escreve código.

**Solução:** Cada conceito deve ter um programa correspondente. Leu sobre ownership? Escreva 5 programas com `Box`, `Rc`, `&T`. Leu sobre lifetimes? Implemente uma estrutura com referências.

### ❌ Erro 3: Copiar Código de Tutoriais

**Problema:** Você copia o código do instrutor mas não entende.

**Solução:** Escreva do zero. Se travar, pesquise o conceito (não o código pronto). Delete e reescreva até sair natural.

### ❌ Erro 4: Evitar `unsafe` e FFI

**Problema:** Você acha que nunca vai precisar de `unsafe`.

**Solução:** Projetos reais precisam de FFI (C libraries), allocators customizados, otimizações críticas. Você precisa entender `unsafe` para saber **quando** usá-lo (e quando NÃO usar). Implemente um allocator simples no Projeto 1.

### ❌ Erro 5: Não Usar Debugger

**Problema:** Você usa `println!` debugging para tudo.

**Solução:** Aprenda LLDB (ou GDB). Um breakpoint vale mais que 100 printlns. Use `rust-lldb` para ver memória, stack, heap em tempo real. Você precisa ver ownership funcionando na prática.

---

## Checklist de 4-5 Meses (Rota 100% Rust)

### Mês 1: Fundamentos de Hardware

- [ ] Leia "Code" (Petzold)
- [ ] Assista série Ben Eater (YouTube)
- [ ] Faça Nand2Tetris (Projetos 1-6: hardware)
- [ ] Experimente Compiler Explorer (Rust → Assembly)

### Mês 2: Rust Básico

- [ ] Leia "The Rust Book" (Capítulos 1-8)
- [ ] Faça Rustlings (https://github.com/rust-lang/rustlings)
- [ ] Leia CS:APP (Capítulos 1-3) — Hardware e representação de dados
- [ ] Escreva 10 programas Rust simples (CLI tools)

### Mês 3: Ownership e Memória

- [ ] Leia "The Rust Book" (Capítulos 4, 10, 15) — Ownership, Lifetimes, Smart Pointers
- [ ] Leia "Too Many Lists" (https://rust-unofficial.github.io/too-many-lists/)
- [ ] Implemente LinkedList, Stack, Queue, Vec em Rust
- [ ] 📖 **Opcional**: Se travar, leia Beej's Guide (ponteiros em C) por 1-2 dias

### Mês 4: Unsafe e Allocators

- [ ] Leia "Rust for Rustaceans" (Capítulos 1-5)
- [ ] Implemente allocator básico (unsafe Rust)
- [ ] Use Miri para detectar undefined behavior
- [ ] Assista "Crust of Rust" (Jon Gjengset YouTube)

### Mês 5: Sistemas Operacionais e Concorrência

- [ ] Leia OSTEP (Capítulos 1-14) — Processos, memória virtual, concorrência
- [ ] Implemente shell Unix (Rust com `std::process`)
- [ ] Implemente servidor TCP echo (síncrono e async com tokio)
- [ ] Use strace/ltrace nos seus programas
- [ ] Leia "Writing an OS in Rust" (até multiprocessing)
- [ ] Comece [`01-validador-cpf-basico`](../01-validador-cpf-basico/00-visao-geral.md)

---

## Próximos Passos

Quando completar esta fase:

1. Leia [`engenharia.md`](engenharia.md) — Veja onde você está no caminho completo
2. Comece [`01-validador-cpf-basico`](../01-validador-cpf-basico/00-visao-geral.md) — Projeto guiado (Fase 2)
3. Consulte [`../security/checklist-desenvolvimento-seguro.md`](../security/checklist-desenvolvimento-seguro.md) — Quando começar a codar

---

## Conclusão

Fase 1 é a mais frustrante, mas também a mais importante.

Você pode pular, mas pagará o preço depois:

- Debugs que levam horas porque você não entende memória
- Performance que nunca consegue otimizar
- Dependência eterna de frameworks
- Medo de linguagens de sistemas

**Você pode investir 4-5 meses agora** e ter fundação para o resto da carreira.

### O que Importa

Não importa a linguagem. O que importa é:

1. ✅ **Você entende como a máquina funciona** (CPU, memória, processos)
2. ✅ **Você não tem medo de syscalls** (open, read, write, close)
3. ✅ **Você consegue debugar sem IDE** (gdb ou lldb, strace, logs)
4. ✅ **Você sabe quando algo é caro** (heap allocation, syscall, context switch)

Se você tem essas 4 habilidades, **a linguagem é apenas sintaxe**.

---

## Recursos Finais (Rota 100% Rust)

### 📚 Livros (Prioridade)

**Obrigatórios:**

1. ⭐⭐⭐⭐⭐ **"The Rust Programming Language"** (GRATUITO) — Comece aqui
2. ⭐⭐⭐⭐⭐ **"Rust for Rustaceans"** (Jon Gjengset) — Depois de The Book

**Complementares:** 3. ⭐⭐⭐⭐⭐ **"Computer Systems: A Programmer's Perspective"** — Conceitos (não código) 4. ⭐⭐⭐⭐ **"Programming Rust"** (O'Reilly) — Referência completa

**📖 Opcional (apenas conceitos SE travar):**

- **"Beej's Guide to C"** (GRATUITO) — Apenas capítulo de ponteiros
- **"Pointer Basics"** (Stanford, PDF) — Diagramas visuais

### 🌐 Online (Prioridade)

**Obrigatórios:**

1. ⭐⭐⭐⭐⭐ **Rust by Example** (https://doc.rust-lang.org/rust-by-example/)
2. ⭐⭐⭐⭐⭐ **Too Many Lists** (https://rust-unofficial.github.io/too-many-lists/)
3. ⭐⭐⭐⭐⭐ **Rustlings** (https://github.com/rust-lang/rustlings)
4. ⭐⭐⭐⭐⭐ **Jon Gjengset YouTube** (https://www.youtube.com/@jonhoo)

**Complementares:** 5. ⭐⭐⭐⭐ **Writing an OS in Rust** (https://os.phil-opp.com/) 6. ⭐⭐⭐⭐ **Rust Atomics and Locks** (Mara Bos, livro online) 7. ⭐⭐⭐⭐ **Compiler Explorer** (https://godbolt.org/) — Veja Rust → Assembly

### 👥 Comunidade

**Faça perguntas aqui:**

- **Discord Rust** (https://discord.gg/rust-lang) — Mais ativo
- **r/rust** (Reddit) — Boas discussões técnicas
- **users.rust-lang.org** (forum oficial) — Respostas detalhadas

**Siga no Twitter/X:**

- @jonhoo (Jon Gjengset)
- @m_ou_se (Mara Bos — std lib team)
- @withoutboats (async Rust)

### 🛠️ Ferramentas Obrigatórias

- **rustup** — Gerenciador de versões Rust
- **Clippy** — Linter (use sempre)
- **rust-analyzer** — LSP para VS Code
- **Miri** — Detecta undefined behavior
- **cargo-expand** — Veja macros expandidas
- **rust-lldb** — Debugger

---

**Boa sorte. Você vai precisar. 🔥**

**E lembre-se:** A jornada de engenharia é longa. Fase 1 é apenas o começo. Mas é o começo que separa os que passam dos que apenas tentam.

**Você escolheu a rota Rust. Quando o borrow checker te frustrar, lembre-se: ele está te ensinando. A frustração é temporária. O conhecimento é permanente.**
