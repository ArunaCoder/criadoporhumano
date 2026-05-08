# Guia de Sandbox e Isolamento com Rust e Docker

## Introdução

Quando falamos de **Sandbox**, estamos criando camadas de isolamento para garantir que, caso um atacante consiga explorar uma falha lógica na sua aplicação, ele continue preso em uma "caixa" sem poder infectar o host ou roubar dados sensíveis do sistema operacional.

Para um engenheiro raiz, **segurança não é um plugin; é arquitetura**. Veja como estruturamos isso:

---

## 1. O Binário Estático

Em Rust, o primeiro passo é compilar o binário de forma **estática**. Queremos que ele seja um arquivo único, contendo tudo o que precisa para rodar, sem depender de bibliotecas dinâmicas (`.so`) espalhadas pelo sistema.

### Benefícios

- Portabilidade total
- Sem dependências externas
- Menor superfície de ataque

---

## 2. Docker Multi-Stage (O Filtro de Gordura)

Não faz sentido ter um compilador, gerenciador de pacotes (`Cargo`) ou ferramentas de shell dentro do seu container de produção. Isso só **aumenta a superfície de ataque**.

Usamos o padrão **Multi-Stage**:

### Stage de Build

Usa uma imagem pesada (Rust oficial) para compilar o código.

### Stage Final

Copia apenas o binário resultante para uma imagem mínima.

### Por que Alpine ou Distroless?

- **Alpine**: É o minimalismo em forma de distro. Usa `musl libc` em vez da pesada `glibc`. Pesa cerca de **5MB**.
- **Distroless (Google)**: O nível máximo de paranoia. Não tem shell (`sh`/`bash`), não tem gerenciador de pacotes, não tem nada. Apenas o seu binário e as bibliotecas mínimas de runtime. Se o atacante entrar, ele não tem nem um comando `ls` para listar arquivos.

---

## 3. O Princípio do Menor Privilégio (Non-Root User)

Por padrão, o Docker roda processos como **root**. Se alguém "quebra" o container, ele vira root na sua máquina host. **Isso é amadorismo**.

No `Dockerfile`, criamos um usuário sem poderes e mudamos o contexto de execução:

```dockerfile
# Exemplo de configuração
RUN adduser -D -s /bin/nologin appuser
USER appuser
```

---

## 4. Isolamento de Recursos (Cgroups e Namespaces)

Ao rodar esse container, o **Kernel do Linux** usa:

- **Namespaces**: Para dizer ao processo: "Você só enxerga estes arquivos e este IP"
- **Cgroups**: Para limitar: "Você só pode usar 128MB de RAM e 10% de CPU"

Se o seu código Rust tiver um vazamento de memória (difícil, mas não impossível com `unsafe`), o Cgroup **mata o processo** antes que ele derrube o servidor inteiro.

---

## 5. Por que Rust brilha aqui?

Diferente de Java (JVM), Python ou Node.js, o Rust **não precisa de uma "VM"** rodando dentro do container. O binário fala direto com o Kernel. Isso significa:

- **Cold Start instantâneo**
- **Consumo de memória ridículo** (geralmente < 20MB para APIs simples)
- **Segurança preemptiva**: O binário é imutável e assinado

---

## Conclusão

Entendeu a lógica? O container não é para "facilitar o deploy", é uma **trincheira**. Se o inimigo pular o muro, ele cai em um quarto vazio, sem ferramentas e sem saída.

### Próximos Passos

Qual parte dessa pilha de isolamento você quer que eu aprofunde:

- A otimização do binário estático?
- As capacidades de rede do container?
