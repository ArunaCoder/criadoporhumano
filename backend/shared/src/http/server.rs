use std::net::TcpListener;
use std::time::Duration;

use crate::http::request::HttpRequest;

pub fn start_server(addr: &str) -> std::io::Result<()> {
    let listener = TcpListener::bind(addr)?;
    println!("Listening on {}", addr);

    for stream in listener.incoming() {
        let stream = stream?;
        println!("Nova conexão estabelecida!");
        stream.set_read_timeout(Some(Duration::from_secs(5)))?;
        stream.set_write_timeout(Some(Duration::from_secs(5)))?;
        handle_connection(stream);
    }

    Ok(())
}

fn handle_connection(stream: std::net::TcpStream) {
    use std::io::BufReader;

    let mut reader = BufReader::new(stream);

    match HttpRequest::parse(&mut reader) {
        Ok(req) => {
            println!("✅ Request válida:");
            println!("   Method: {}", req.method);
            println!("   Path: {}", req.path);
            // TODO Enviar HttpResponse
        }
        Err(e) => {
            eprintln!("❌ Parse error: {}", e);
            // TODO Enviar HTTP 400 Bad Request
        }
    }
}

/*
═══════════════════════════════════════════════════════════════════════════════
NOTAS SOBRE OWNERSHIP, BORROWING E LIFETIMES NESTE ARQUIVO
═══════════════════════════════════════════════════════════════════════════════

1. PARÂMETRO `addr: &str` em `start_server()`
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • Recebe EMPRÉSTIMO IMUTÁVEL de uma string slice
   • Por quê? Não precisamos possuir o endereço, só ler ele uma vez
   • `bind(addr)` aceita `&str` — Rust copia os bytes internamente se necessário
   • Lifetime: `addr` vive apenas durante a chamada de `start_server()`

2. OWNERSHIP DO `TcpStream` no loop
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • `listener.incoming()` retorna iterador que PRODUZ `Result<TcpStream, Error>`
   • `let stream = stream?` DESEMPACOTA e ASSUME OWNERSHIP do TcpStream
   • Por quê possuir? TcpStream é um recurso de sistema (file descriptor)
   • Ownership garante que o socket será fechado quando sair de escopo

3. TRANSFERÊNCIA DE OWNERSHIP para `handle_connection()`
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • `handle_connection(stream)` MOVE ownership do stream para a função
   • Após essa linha, `stream` não pode mais ser usado no loop
   • Por quê mover? A função precisa de controle total (ler, escrever, fechar)
   • Quando `handle_connection()` termina, stream é dropado = conexão fecha

4. PARÂMETRO `mut stream: TcpStream` em `handle_connection()`
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • Recebe ownership E marca como mutável
   • Por quê mut? Precisamos criar `BufReader` com `&mut stream`
   • TcpStream NÃO implementa `Copy` (recursos de sistema nunca são Copy)

5. EMPRÉSTIMO MUTÁVEL para `BufReader::new(&mut stream)`
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • `BufReader::new()` EMPRESTA mutavelmente o stream
   • BufReader NÃO assume ownership — só mantém uma referência
   • Por quê? Precisamos poder usar `reader` múltiplas vezes (futuras operações)
   • Enquanto `reader` existir, não podemos usar `stream` diretamente

6. `reader.by_ref()` — EMPRÉSTIMO DA REFERÊNCIA
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • `by_ref()` cria &mut BufReader (referência do reader)
   • Por quê? `.take()` CONSOME o reader — teríamos que recriar depois
   • Com `by_ref()`, apenas emprestamos — reader continua disponível
   • Lifetime: a referência vive apenas na linha onde usamos `.take()`

7. `.take(MAX_LINE_SIZE)` — ADAPTADOR QUE CONSOME
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • `take()` cria um adaptador `Take<&mut BufReader<&mut TcpStream>>`
   • Esse adaptador LIMITA quantos bytes podem ser lidos
   • Nota: `limited` contém REFERÊNCIA emprestada do reader
   • Quando `limited` sai de escopo, o empréstimo é devolvido

═══════════════════════════════════════════════════════════════════════════════
DIAGRAMA DE OWNERSHIP/BORROWING
═══════════════════════════════════════════════════════════════════════════════

start_server()
    │
    └─> TcpStream [OWNED] ──────move──────> handle_connection(stream)
                                                   │
                                                   ├─> &mut stream ──borrow──> BufReader
                                                   │        │
                                                   │        └──> &mut reader ──borrow──> Take
                                                   │                 │
                                                   │                 └─> read_line(&mut buffer)
                                                   │
                                                   └─> [stream dropped aqui = conexão fecha]

═══════════════════════════════════════════════════════════════════════════════
POR QUE ESSAS DECISÕES?
═══════════════════════════════════════════════════════════════════════════════

✓ Ownership de TcpStream garante: conexões sempre fecham (RAII)
✓ Empréstimo mutável para BufReader: evita cópia do stream (eficiência)
✓ by_ref() no reader: permite reusar reader em operações futuras
✓ Lifetime curta de `limited`: libera empréstimo imediatamente após uso

═══════════════════════════════════════════════════════════════════════════════
ERRO COMUM QUE ISSO PREVINE
═══════════════════════════════════════════════════════════════════════════════

// ❌ ISTO NÃO COMPILA:
let reader = BufReader::new(&mut stream);
let limited = reader.take(8192);  // take() CONSOME reader!
// reader não existe mais aqui — erro de compilação

// ✅ ISTO COMPILA:
let mut reader = BufReader::new(&mut stream);
let limited = reader.by_ref().take(8192);  // Apenas empresta reader
// reader ainda existe aqui — pode ser usado depois

═══════════════════════════════════════════════════════════════════════════════
DIFERENÇA ENTRE `.by_ref()` E O OPERADOR `&`
═══════════════════════════════════════════════════════════════════════════════

PERGUNTA: Por que não usar apenas `(&reader).take()`?

RESPOSTA: São conceitos diferentes com propósitos diferentes.

1. OPERADOR `&` (referência básica)
   ────────────────────────────────────────────────────────────────────────────
   • Sintaxe de linguagem para criar referências
   • `&valor` cria referência imutável
   • `&mut valor` cria referência mutável
   • Usado para emprestar valores em geral

2. MÉTODO `.by_ref()` (referência de iterator)
   ────────────────────────────────────────────────────────────────────────────
   • Método específico do trait `Iterator`
   • Retorna adaptador que implementa `Iterator` sobre `&mut Self`
   • Permite usar métodos consumidores (como `.take()`) sem consumir o original
   • Funciona porque retorna tipo que implementa os traits necessários

EXEMPLO DO PROBLEMA:

// ❌ ISTO NÃO COMPILA:
let limited = (&reader).take(8192);
// Erro: `&BufReader` não implementa o trait necessário que `take()` espera

// ❌ ISTO TAMBÉM NÃO COMPILA:
let limited = (&mut reader).take(8192);
// Erro: `take()` espera `Self` (consome), não `&mut Self`

// ✅ ISTO COMPILA:
let limited = reader.by_ref().take(8192);
// Funciona: `by_ref()` retorna `&mut BufReader` mas de forma que `take()` aceita

POR QUE `by_ref()` FUNCIONA?

A assinatura de `take()` é:
    fn take(self, limit: u64) -> Take<Self>

Ele consome `self`. Mas quando você faz `reader.by_ref()`, retorna um tipo especial
que implementa os mesmos traits (`Read`, `BufRead`) e pode ser consumido pelo
`take()` SEM consumir o `reader` original.

É como se `by_ref()` criasse um "proxy temporário" que pode ser destruído sem
afetar o reader original.

ANALOGIA:

`&` é como dar seu documento original para alguém ler (empréstimo)
`.by_ref()` é como dar uma fotocópia que pode ser descartada (proxy consumível)

═══════════════════════════════════════════════════════════════════════════════
*/
