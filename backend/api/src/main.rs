use shared::{ServerConfig, http};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = ServerConfig::new(None)?;
    println!("Servidor iniciado. Root: {:?}", config.base_canonical);
    http::server::start_server("127.0.0.1:8080", &config)?;
    Ok(())
}
