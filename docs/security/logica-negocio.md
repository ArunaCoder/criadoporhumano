# Vulnerabilidades de Lógica de Negócio

## Introdução

Mesmo com o Rust garantindo que você não terá um **Buffer Overflow** ou um **Dangling Pointer**, o compilador não pode impedir você de escrever uma lógica de negócio estúpida. A **vulnerabilidade lógica** é aquela onde o código faz exatamente o que você escreveu, mas o que você escreveu é inerentemente inseguro.

Aqui estão os principais vetores de falha conceitual que um engenheiro precisa vigiar:

---

## 1. Quebra de Controle de Acesso a Nível de Objeto (IDOR)

Este é o erro clássico de **"confiança cega"**. Imagine que você tem uma rota para baixar uma fatura: `/api/fatura/123`.

O erro ocorre quando o backend verifica se o usuário está autenticado, mas **não verifica** se aquela fatura pertence àquele usuário.

### O Ataque

O atacante simplesmente muda o ID na URL para `124`, `125`, e começa a colher dados de outros clientes.

### O Conceito

**Autenticação** (quem é você) é diferente de **Autorização** (o que você pode fazer). Falhar na segunda é abrir a porta para o vazamento em massa.

---

## 2. Race Conditions de Negócio (TOCTOU)

Sigla para **Time-of-Check to Time-of-Use**. Isso acontece quando há um intervalo de tempo entre a verificação de uma condição e a execução da ação.

### Exemplo Conceitual: Um sistema de saque de saldo

1. O sistema verifica: "O usuário tem R$ 100?" (Sim)
2. O sistema processa o saque

### O Ataque

Se o atacante enviar **50 requisições simultâneas** em milissegundos, e o seu backend não usar travas atômicas ou transações de banco de dados com isolamento correto, todas as 50 verificações podem retornar "Sim" antes que o primeiro débito seja registrado.

O atacante saca **R$ 5.000** tendo apenas **R$ 100**.

---

## 3. Esgotamento de Recursos (DoS Lógico)

Aqui o atacante não derruba seu servidor com tráfego pesado (DDoS), mas com uma **única requisição "pesada"**.

### Exemplo

Você cria um endpoint que gera um relatório em PDF de todas as transações de um usuário. Você não coloca um limite de data ou de quantidade.

### O Ataque

O atacante solicita um relatório de "todos os tempos" para uma conta com **milhões de registros**. O seu backend Rust vai tentar alocar memória e CPU para processar isso, travando a thread ou estourando o limite do container (OOM Kill), derrubando o serviço para todos os outros.

---

## 4. Injeção de Parâmetros e Poluição de Lógica

Isso ocorre quando o backend aceita parâmetros que influenciam o comportamento interno de forma não prevista.

### Exemplo

Um sistema de e-commerce onde o preço é calculado no frontend e enviado para o backend:

```json
{ "produto_id": 1, "preco": 0.01 }
```

### O Ataque

O atacante altera o preço no `fetch` do Vanilla JS antes de enviar. Se o backend não revalidar o preço consultando a **"fonte da verdade"** (o banco de dados), ele processa a venda por um valor ínfimo.

---

## 5. Falha na Máquina de Estados

Sistemas complexos geralmente seguem um fluxo:

```
Pedido Criado → Pagamento Confirmado → Enviado
```

### O Ataque

O atacante tenta **pular etapas**. Ele envia uma requisição diretamente para o endpoint de "Confirmar Envio" sem nunca ter passado pelo "Pagamento".

### O Erro

O código do backend assume que, se a função foi chamada, as etapas anteriores ocorreram.

> Um engenheiro raiz desenha o backend como uma **Máquina de Estados Finitos**, onde é impossível transitar para "Enviado" se o estado atual não for "Pago".

---

## 6. Vazamento de Informação por Timing (Timing Attacks)

Este é o nível mais **sutil**. O tempo que seu servidor leva para responder pode dizer algo ao atacante.

### Exemplo

Ao validar uma senha:

- Responde `"Usuário não encontrado"` em **10ms**
- Responde `"Senha incorreta"` em **50ms**

O atacante agora sabe quais e-mails existem na sua base.

### Conceito

O processamento deve ser o mais **constante** possível, ou as mensagens de erro devem ser **genéricas** (`"Credenciais inválidas"`), para não dar pistas sobre o estado interno dos dados.

---

## Conclusão

A segurança em Rust protege você contra o **"como"** o programa quebra (memória), mas essas falhas acima tratam do **"o que"** o programa faz.

Entende por que o SQL puro e o controle total do fluxo são cruciais? Se você não entende cada passo da transação, você deixa essas brechas abertas.
