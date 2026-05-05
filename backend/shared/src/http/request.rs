use ::std::path::{Path, PathBuf};
use std::collections::HashMap;
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
        const TYPICAL_LINE_SIZE: usize = 1024; // 1KB covers 99% of real requests
        const MAX_HEADERS: usize = 100;

        // Pre-allocate buffer for typical case (optimization vs fragmentation)
        let mut line = String::with_capacity(TYPICAL_LINE_SIZE);

        let mut limited = reader.by_ref().take(MAX_LINE_SIZE as u64);
        limited
            .read_line(&mut line)
            .map_err(|e| format!("Error reading request line: {}", e))?;

        if line.len() >= MAX_LINE_SIZE && !line.ends_with('\n') {
            return Err("414 URI Too Long".to_string());
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

        // Parse HTTP headers with protection against HashDoS
        let mut headers: HashMap<String, String> = HashMap::with_capacity(15);

        loop {
            line.clear(); // Reuse buffer - maintains capacity, zero heap allocation cost

            let bytes_read = reader
                .by_ref()
                .take(MAX_LINE_SIZE as u64)
                .read_line(&mut line)
                .map_err(|e| e.to_string())?;

            // Protection: header line too large (DoS attempt)
            if bytes_read >= MAX_LINE_SIZE && !line.ends_with('\n') {
                return Err("431 Request Header Fields Too Large".to_string());
            }

            // End of headers (empty line in HTTP protocol)
            let trimmed = line.trim();
            if trimmed.is_empty() {
                break;
            }

            // Protection: too many headers (HashDoS attack)
            if headers.len() >= MAX_HEADERS {
                return Err("Too many headers".to_string());
            }

            // Parse header without extra allocations
            if let Some((key, value)) = trimmed.split_once(':') {
                headers.insert(
                    key.trim().to_lowercase(), // Normalize for case-insensitive lookup
                    value.trim().to_string(),
                );
            }
        }

        Ok(HttpRequest {
            method: method.to_string(),
            path: path.to_string(),
            headers,
            body: String::new(),
        })
    }
}
