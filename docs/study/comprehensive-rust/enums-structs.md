**12/05/2026**

# Diferença entre structs e enums:

<https://gemini.google.com/gem/d21fb5c81e2f/fba83539358845eb>

## Engenharia de Memória: Structs vs. Enums no Rust

No desenvolvimento soberano, entender o layout de memória é a diferença entre um código que domina o hardware e um código "preguiçoso" que apenas consome ciclos de CPU.

---

### 1. Struct (Tipo Produto - AND)

A `struct` é uma representação **aditiva**. Todos os campos coexistem fisicamente na memória ao mesmo tempo.

- **Comportamento:** `Campo A` **E** `Campo B`.
- **Layout:** Os campos são dispostos sequencialmente. O Rust reordena os campos para minimizar o _padding_ (espaço vazio para alinhamento de memória).
- **Tamanho:** $\text{Soma do tamanho de todos os campos} + \text{Padding de alinhamento}$.
- **Hardware:** O acesso a cada campo é feito via um _offset_ fixo a partir do endereço base. É ideal para registros de dados e entidades.

### 2. Enum (Tipo Soma - OR)

O `enum` é uma **Tagged Union** (União Etiquetada). Ele representa uma escolha mútua exclusiva; apenas uma variante está "ativa" por vez.

- **Comportamento:** `Variante A` **OU** `Variante B`.
- **Layout:** Utiliza um **Discriminant** (Tag) para identificar a variante ativa. O espaço para o dado (_payload_) é compartilhado; todas as variantes ocupam o mesmo endereço físico de memória.
- **Tamanho:** $\text{Tamanho da maior variante} + \text{Tamanho do Discriminant} + \text{Padding}$.
- **Hardware:** No nível de instrução, o `match` se traduz em um _branch_ (desvio) ou _jump table_ baseado no valor da Tag.

---

### Comparativo Técnico: Struct vs. Enum

#### 1. Gestão de Memória

- **Struct (Empilhamento Estático):** Opera sob a lógica do "E" (AND). Todos os campos coexistem em endereços contíguos. A memória é alocada para o conjunto completo de dados simultaneamente.
- **Enum (Reuso/Sobrescrita):** Opera sob a lógica do "OU" (OR). É um buffer único que hospeda diferentes layouts. Quando você muda a variante, os bits são sobrescritos no mesmo endereço físico.

#### 2. Dimensionamento (Footprint)

- **Struct (Variável):** O tamanho total é a soma aritmética de todos os campos, acrescida dos bytes de _padding_ necessários para o alinhamento de memória (ex: alinhar um `u64` em endereços múltiplos de 8).
- **Enum (Fixo):** O tamanho é invariável, determinado pela maior variante possível mais o byte do discriminante (tag). O compilador reserva o "pior cenário" de espaço para garantir que qualquer variante caiba ali.

#### 3. Densidade de Dados

- **Struct (Baixa):** Cada bit de informação ocupa seu próprio espaço exclusivo. Se você tem 10 campos, paga o preço de 10 campos no barramento de dados, mesmo que use apenas dois em determinado momento.
- **Enum (Alta):** Máxima eficiência de cache. Como diferentes variantes compartilham os mesmos bytes, você mantém a estrutura "magra", otimizando a localidade de referência e evitando _cache misses_ desnecessários.

#### 4. Aplicação Arquitetural

- **Struct (Registro de Dados):** Utilizada para modelar entidades estáticas e agregados de informação. É o "D" (Data) do DTO, onde a estrutura é previsível e persistente.
- **Enum (Máquina de Estados):** É a base do polimorfismo estático. Permite modelar transições de estado e lógicas complexas sem a sujeira de ponteiros de função ou tabelas de métodos virtuais (VTable), resolvendo tudo em tempo de compilação.

---

### 4. A Genialidade do Rust: Niche Optimization

Diferente de linguagens "modinhas", o compilador Rust aplica **Otimização de Nicho** para reduzir o custo da Tag a **zero**.

- **Exemplo:** `Option<&T>`
  - Como uma referência (`&T`) nunca pode ser nula (`0x0`), o Rust usa o valor `0x0` para representar a variante `None`.
  - **Custo:** O `Option<&T>` ocupa exatamente o mesmo espaço que um ponteiro simples (8 bytes em 64 bits).

- **Exemplo:** `Option<bool>`
  - Um `bool` só usa os valores `0x00` e `0x01`. O Rust usa `0x02` para o `None`.
  - **Custo:** Mantém o tamanho total em apenas 1 byte.

---

### 5. Veredito do Engenheiro

- Use **Struct** quando precisar de um conjunto fixo de dados que define um objeto.
- Use **Enum** para controle de fluxo, estados e tratamento de erros.
- **Dica de Performance:** Ordene os campos da sua `struct` do maior para o menor ou confie no `repr(Rust)` para evitar desperdício com padding.
