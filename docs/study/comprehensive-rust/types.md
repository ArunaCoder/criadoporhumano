**12/05/2026**

# Engenharia de Tipos em Rust: Alias vs. Newtype

No desenvolvimento de sistemas de alta performance, a clareza do código e a segurança em tempo de compilação são inegociáveis. O Rust oferece duas ferramentas distintas para lidar com nomes de tipos, cada uma com um propósito técnico específico: o **Type Alias** e o **Newtype Pattern**.

## 1. Type Alias (`type`)

O `type alias` é uma substituição puramente léxica. Ele não cria um tipo novo na tabela de símbolos do compilador; ele apenas define um sinônimo.

### Casos de Uso Legítimos

- **Simplificação de Assinaturas Complexas:** Reduzir o ruído visual de tipos genéricos aninhados que dificultam a leitura do código (ex: `Arc<RwLock<T>>`).
- **Abstração de Dependências (Soberania de Código):** Evitar o acoplamento direto com nomes de bibliotecas externas. Se você trocar a crate, altera apenas o alias no ponto central.

### Exemplo: Evitando o Bloat e Acoplamento

```rust
// Em vez de espalhar o tipo da biblioteca externa por todo o projeto:
type DatabaseConn = sqlx::Postgres;

// E em vez de repetir assinaturas complexas:
type CacheMap = std::sync::Arc<std::sync::RwLock<std::collections::HashMap<String, Vec<u8>>>>;

fn process_cache(cache: CacheMap) {
    // O código foca na lógica, não no "espaguete" de tipos.
}
```

---

## 2. Newtype Pattern (`struct`)

O Newtype consiste em encapsular um tipo primitivo ou existente dentro de uma `tuple struct` de um único elemento. Ao contrário do alias, o Newtype cria um **tipo distinto**.

### Por que é Superior para Lógica de Negócio?

- **Segurança de Memória e Lógica:** Impede que grandezas fisicamente diferentes (ex: IDs de tabelas distintas ou unidades de medida como Km e Milhas) sejam operadas entre si por erro humano.
- **Zero-Cost Abstraction:** O Rust garante que, após a compilação, o invólucro seja removido. O binário final tratará o Newtype exatamente como o tipo interno (ex: um `f64`), sem overhead de memória ou CPU.

### Exemplo: Blindagem de Domínio

```rust
struct Quilometros(f64);
struct Milhas(f64);

// O compilador trava qualquer tentativa de somar Quilometros com Milhas diretamente.
// Para operar, o desenvolvedor é obrigado a implementar a conversão explícita (Trait From).
fn adicionar_distancia(base: Quilometros, extra: Quilometros) -> Quilometros {
    Quilometros(base.0 + extra.0)
}
```

---

## Veredito Técnico

- **Use `type`** para gerenciamento de complexidade visual e manutenção de contratos técnicos. Ele serve para o programador ler melhor o que já existe sem criar barreiras artificiais.
- **Use `struct` (Newtype)** para aplicar as regras do seu domínio no compilador. Ele serve para impedir que o código execute operações semanticamente erradas, movendo o erro do runtime para o tempo de compilação.
