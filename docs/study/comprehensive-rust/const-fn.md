# Hierarquia de Avaliação: Literais, Const FN e Inicialização Estática

<https://gemini.google.com/gem/d21fb5c81e2f/7958001a7152c02c>

## 1. O Escalar Puro (Literal)

- **Uso:** Quando o valor é atômico e imutável por natureza (ex: `const MAX_RETRIES: u8 = 5;`).
- **Mecânica:** O compilador faz a substituição direta do valor em cada ponto de uso. Não ocupa espaço fixo na seção de dados, agindo como um "find and replace" seguro.
- **Veredito:** Use sempre que o valor for conhecido e não derivado. É a forma mais bruta de performance.

## 2. A Função Constante (`const fn`)

- **Uso:** Quando o valor depende de uma lógica, cálculo matemático ou ramificação (if/else), mas os insumos são conhecidos no compile-time.
- **Mecânica:** O compilador executa a lógica da função durante a compilação. O custo de execução é pago pelo desenvolvedor, entregando para o usuário um valor já processado.
- **Veredito:** Essencial para manter a "Single Source of Truth" sem o custo de manutenção de tabelas manuais. Transforma código em dados puros no binário.

## 3. Variáveis Estáticas (`static`)

- **Uso:** Quando você precisa de um local único e fixo na memória para dados (ex: uma tabela de busca ou configuração global).
- **Mecânica:** Diferente da `const`, o `static` possui um endereço de memória definido na seção `.data` ou `.rodata`. Evita que grandes volumes de dados sejam copiados para a stack repetidamente.
- **Veredito:** Use para estruturas grandes ou quando a identidade (endereço de memória) do dado for importante.

## 4. Inicialização Segura Tardia (`OnceLock`)

- **Uso:** Para "estáticos complexos" que o compilador ainda não consegue resolver (ex: cálculos que dependem de estado do SO ou lógicas ainda não suportadas por `const fn`).
- **Mecânica:** Garante que a inicialização ocorra exatamente uma vez no primeiro acesso (thread-safe), sem os riscos de `static mut` ou a opacidade de crates externos.
- **Veredito:** O último recurso. Use apenas quando a soberania do compilador termina e a necessidade do runtime começa.

## Resumo da Decisão

1. Se o valor é fixo: **Literal**.
2. Se o valor é calculado de outros fixos: **const fn**.
3. Se o dado é grande e único: **static** (inicializado por uma `const fn`).
4. Se o cálculo exige o mundo exterior: **OnceLock**.
