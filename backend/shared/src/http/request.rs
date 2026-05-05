use ::std::path::{Path, PathBuf};
use std::env;
use std::io::{BufRead, BufReader, Read};
use std::net::TcpStream;

pub struct HttpRequest {
    pub method: String,
    pub path: String,
    pub headers: std::collections::HashMap<String, String>,
    pub body: String,
}

impl HttpRequest {
    pub fn parse(reader: &mut BufReader<TcpStream>) -> Result<Self, String> {
        const MAX_LINE_SIZE: usize = 8192;

        // Ler primeira linha contra ataques DoS
        let mut line = String::new();
        let mut limited = reader.by_ref().take(MAX_LINE_SIZE as u64);
        limited
            .read_line(&mut line)
            .map_err(|e| format!("Error reading request line: {}", e))?;

        if line.len() >= MAX_LINE_SIZE {
            return Err("Request line too large".to_string());
        }

        // Parsear linha de request
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() != 3 {
            return Err("Invalid request line: expected METHOD PATH VERSION".to_string());
        }

        let method = parts[0];
        let path = parts[1];
        let version = parts[2];

        // Validar HTTP
        const ALLOWED_METHODS: &[&str] = &["GET", "POST", "HEAD", "OPTIONS"];
        if !ALLOWED_METHODS.contains(&method) {
            return Err(format!("Method not allowed: {}", method));
        }

        if version != "HTTP/1.1" && version != "HTTP/1.0" {
            return Err("HTTP version not supported".to_string());
        }

        let base_dir = env::var("PUBLIC_DIR").unwrap_or_else(|_| "public".to_string());

        let base = PathBuf::from(base_dir);

        let requested = base.join(path.trim_start_matches('/'));

        let canonical = requested
            .canonicalize()
            .map_err(|_| "invalid path or file not found".to_string())?;

        let base_canonical = base
            .canonicalize()
            .map_err(|_| "Failed to resolve base directory".to_string())?;

        if !canonical.starts_with(&base_canonical) {
            return Err("Path traversal detected".to_string());
        }

        if path.contains("..") || path.contains("//") {
            return Err("Invalid path".to_string());
        }

        Ok(HttpRequest {
            method: method.to_string(),
            path: path.to_string(),
            headers: std::collections::HashMap::new(),
            body: String::new(),
        })
    }
}
