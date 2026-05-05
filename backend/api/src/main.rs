use shared::http;

fn main() {
    if let Err(e) = http::server::start_server("127.0.0.1:8080") {
        eprintln!("Erro ao iniciar servidor: {}", e);
    }
}
