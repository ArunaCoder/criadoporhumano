use std::io::Write;
use std::net::TcpListener;
use std::time::Duration;

use crate::ServerConfig;
use crate::http::request::HttpRequest;

pub fn start_server(addr: &str, config: &ServerConfig) -> std::io::Result<()> {
    let listener = TcpListener::bind(addr)?;
    println!("Listening on {}", addr);

    for stream in listener.incoming() {
        let stream = stream?;
        println!("Nova conexão estabelecida!");
        stream.set_read_timeout(Some(Duration::from_secs(5)))?;
        stream.set_write_timeout(Some(Duration::from_secs(5)))?;
        handle_connection(stream, config);
    }

    Ok(())
}

fn handle_connection(mut stream: std::net::TcpStream, config: &ServerConfig) {
    use std::io::BufReader;

    let mut reader = BufReader::new(&mut stream);

    match HttpRequest::parse(&mut reader, config) {
        Ok(req) => {
            println!("✅ Request válida:");
            println!("   Method: {}", req.method);
            println!("   Path: {}", req.path);

            // Quick fix: enviar 200 OK vazio
            let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.flush();

            #[cfg(feature = "debug-http")]
            if let Err(e) = req.save_debug("debug_request.txt") {
                eprintln!("⚠️  Failed to save debug file: {}", e);
            } else {
                println!("📝 Debug saved to: debug_request.txt");
            }

            // TODO Enviar HttpResponse
        }
        Err(e) => {
            eprintln!("❌ Parse error: {}", e);
            // Quick fix: enviar 400 Bad Request
            let response = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n";
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.flush();
            // TODO Enviar HTTP 400 Bad Request
        }
    }
}
