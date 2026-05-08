# TOCTOU: Time-of-Check to Time-of-Use

## Introdução

O **TOCTOU** (Time-of-Check to Time-of-Use) é a personificação do caos em sistemas concorrentes. Para um engenheiro, ele é um lembrete humilhante de que o tempo não é contínuo no processador, mas sim uma **sucessão de fatias de execução interrompidas**.

Conceitualmente, o TOCTOU é uma **condição de corrida** (race condition) que explora a janela de oportunidade entre a verificação de uma condição (o "Check") e a execução da operação (o "Use").

---

## O Abismo entre o Check e o Use

Imagine que o seu backend é um balconista de banco. O processo ocorre assim:

1. **Check**: O balconista olha o saldo na tela: "Sim, ele tem R$ 100"
2. **Pausa**: O balconista se vira para pegar o dinheiro na gaveta _(Aqui está a vulnerabilidade)_
3. **Use**: O balconista entrega o dinheiro e subtrai do saldo

### O Problema

O problema é que, no mundo digital e multi-thread do Rust com `tokio` ou `actix`, o "se virar para pegar o dinheiro" leva milissegundos, mas o processador executa **milhões de instruções** nesse meio tempo.

Se o atacante disparar **100 requisições simultâneas**, 10 delas podem conseguir completar o "Check" antes que a primeira tenha finalizado o "Use".

---

## O TOCTOU no Sistema de Arquivos

Este é o exemplo histórico mais clássico.

### Cenário

1. **O Programa**: Verifica se o usuário tem permissão para escrever no arquivo `/tmp/config.txt`
2. **O Atacante**: No exato milissegundo após a verificação, ele deleta o arquivo e cria um **Link Simbólico** (symlink) com o mesmo nome, apontando para o arquivo de senhas do sistema (`/etc/shadow`)
3. **O Resultado**: O programa, achando que ainda está escrevendo no arquivo seguro que ele acabou de checar, escreve dados no coração do sistema operacional

---

## A Ilusão da Atomicidade

O erro de muitos desenvolvedores "nutella" é achar que, porque o código está em linhas sequenciais, ele será executado sem interrupções.

No backend, sua aplicação está **competindo com outras threads e processos**. O Kernel pode pausar sua thread de processamento de pagamento exatamente após o `if (saldo > valor)` para dar CPU a outra tarefa.

Se essa outra tarefa for justamente outra requisição de saque do mesmo usuário, o estado do seu banco de dados se torna **inconsistente**.

---

## Como um Engenheiro Raiz resolve isso?

A solução para o TOCTOU é tornar a operação **Atômica**. Ou seja, o "Check" e o "Use" devem ser uma coisa só, **indivisível**.

### 1. No Banco de Dados (SQL Puro)

Em vez de buscar o saldo, trazer para o Rust, validar e enviar um `UPDATE`, fazemos tudo em uma **única instrução SQL** com uma cláusula `WHERE` agressiva:

```sql
UPDATE contas
SET saldo = saldo - :saque
WHERE id = :usuario_id
  AND saldo >= :saque;
```

> "Atualize o saldo para (saldo - saque) ONDE id = usuario_id E saldo >= saque."

Aqui, o banco de dados **garante a atomicidade**. Se dois pedidos chegarem, o segundo falhará na cláusula `WHERE` porque o primeiro já alterou o saldo.

### 2. No Sistema de Arquivos

Não verificamos permissões antes de abrir. Nós **tentamos abrir o arquivo** com as flags de exclusividade do SO.

O próprio Kernel nos diz se falhou ou não no momento da abertura, sem espaço para trocas de arquivos no meio do caminho.

### 3. Em Memória (Rust)

Usamos primitivas de sincronização como `Mutex`, `RwLock` ou tipos `Atomic`.

O Rust brilha aqui porque o **Borrow Checker** impede que você acesse o dado sem antes adquirir a trava, garantindo que ninguém mude a "verdade" enquanto você está operando sobre ela.

---

## O Custo da Solução

Resolver TOCTOU gera **contenção**. Se todo mundo precisa esperar a trava (lock) para checar e usar, o sistema pode ficar lento.

O desafio da engenharia de performance é projetar o sistema para que essas travas sejam as **menores e mais rápidas possíveis**, ou usar arquiteturas **lock-free** quando o cenário permitir.
