use std::collections::HashMap;
use std::io::{BufRead, BufReader, Read};
use std::net::TcpStream;
use std::path::PathBuf;

use crate::ServerConfig;

pub struct HttpRequest {
    pub method: String,
    pub path: String,
    pub headers: std::collections::HashMap<String, String>,
    pub body: String,
    #[cfg(feature = "debug-http")]
    pub raw_bytes: Vec<u8>,
}

impl HttpRequest {
    pub fn parse(
        reader: &mut BufReader<&mut TcpStream>,
        config: &ServerConfig,
    ) -> Result<Self, String> {
        // descartado o uso, para  o MVP de &'static str como retorno do erro

        // O limite de 2KB equilibra segurança e compatibilidade. Padrões da indústria
        // (Nginx: 8KB) aceitam headers maiores, mas 2KB cobrem casos típicos enquanto mitigam ataques de DoS e injeção.
        // Aumente para 4KB se tokens JWT ou acúmulo de cookies se tornarem um problema.
        const MAX_LINE_SIZE: usize = 2048;
        const TYPICAL_LINE_SIZE: usize = 1024; // 1KB cobre  99% de requests legítimas
        const MAX_HEADERS: usize = 100;

        #[cfg(feature = "debug-http")]
        let mut raw_capture = Vec::new();

        // Pre-allocate buffer for typical case (optimization vs fragmentation)
        let mut line = String::with_capacity(TYPICAL_LINE_SIZE);

        let mut limited = reader.by_ref().take(MAX_LINE_SIZE as u64);
        limited
            .read_line(&mut line)
            .map_err(|e| format!("Error reading request line: {}", e))?;

        #[cfg(feature = "debug-http")]
        raw_capture.extend_from_slice(line.as_bytes());

        if line.len() >= MAX_LINE_SIZE && !line.ends_with('\n') {
            return Err("414 URI Too Long".to_string()); //embora a conversão explícita seja desnecessária, fica claro aqui o custo de alocação. Não será usado .into() justamente para a conversão ficar explícita.
        }

        // Parsear linha de request
        let (method, path, version) = {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() != 3 {
                return Err("Invalid request line: expected METHOD PATH VERSION".to_string());
            }

            // Extraímos os três como Strings independentes
            (
                parts[0].to_string(),
                parts[1].to_string(),
                parts[2].to_string(),
            )
        };

        // Validar HTTP
        const ALLOWED_METHODS: &[&str] = &["GET", "POST", "HEAD", "OPTIONS"];
        if !ALLOWED_METHODS.contains(&method.as_str()) {
            return Err(format!("Method not allowed: {}", method));
        }

        if version != "HTTP/1.1" && version != "HTTP/1.0" {
            return Err("HTTP version not supported".to_string());
        }

        // Parsear headers HTTP com proteção contra HashDoS
        let mut headers: HashMap<String, String> = HashMap::with_capacity(15);

        loop {
            line.clear(); // Reusar buffer - mantém capacidade com zero custo de alocação no heap

            let bytes_read = reader
                .by_ref()
                .take(MAX_LINE_SIZE as u64)
                .read_line(&mut line)
                .map_err(|e| e.to_string())?;

            #[cfg(feature = "debug-http")]
            raw_capture.extend_from_slice(line.as_bytes());

            // Proteção: linha do header muito grande (DoS attempt)
            if bytes_read >= MAX_LINE_SIZE && !line.ends_with('\n') {
                return Err("431 Request Header Fields Too Large".to_string());
            }

            // Fim dos headers (linha vazia no protocolo HTTP)
            let trimmed = line.trim();
            if trimmed.is_empty() {
                break;
            }

            // Proteção: muitos headers (HashDoS attack)
            if headers.len() >= MAX_HEADERS {
                return Err("Too many headers".to_string());
            }

            // Parsear header sem alocações extras
            if let Some((key, value)) = trimmed.split_once(':') {
                headers.insert(
                    key.trim().to_lowercase(), // Normalizar para case-insensitive lookup
                    value.trim().to_string(),
                );
            }
        }
        // Rejeitar sintaxe suspeita (cheap, fast)
        if path.contains("..") || path.contains("//") {
            return Err("Suspicious path syntax".to_string());
        }

        validate_path_traversal(&path, &config.base_canonical)?;

        let mut body = String::new();

        if let Some(content_length_str) = headers.get("content-length") {
            let content_length: usize = content_length_str
                .parse()
                .map_err(|_| "400 Bad Request: Invalid Content-Length".to_string())?;

            const MAX_BODY_SIZE: usize = 8192;

            if content_length > MAX_BODY_SIZE {
                return Err("413 Payload Too Large".to_string());
            };

            let mut body_bytes = vec![0u8; content_length];
            reader
                .read_exact(&mut body_bytes)
                .map_err(|_| "IO Error: Failed to read body")?;

            body = String::from_utf8(body_bytes)
                .map_err(|_| "Invalid UTF8 body request".to_string())?;
        }

        Ok(HttpRequest {
            method: method.to_string(),
            path: path.to_string(),
            headers,
            body,
            #[cfg(feature = "debug-http")]
            raw_bytes: raw_capture,
        })
    }

    #[cfg(feature = "debug-http")]
    pub fn save_debug(&self, path: &str) -> std::io::Result<()> {
        use std::fs::OpenOptions;
        use std::io::Write;
        use std::time::{SystemTime, UNIX_EPOCH};

        // Append mode: adiciona ao final sem sobrescrever
        let mut file = OpenOptions::new()
            .create(true) // Cria se não existir
            .append(true) // Adiciona ao final (preserva requests anteriores)
            .open(path)?;

        // Timestamp para diferenciar requests no mesmo arquivo
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis();

        writeln!(file, "\n")?;
        writeln!(
            file,
            "============================================================"
        )?;
        writeln!(file, "HTTP REQUEST DEBUG DUMP - {}", timestamp)?;
        writeln!(
            file,
            "============================================================\n"
        )?;

        writeln!(file, "--- RAW BYTES (Wire Format) ---")?;
        file.write_all(&self.raw_bytes)?;
        if !self.raw_bytes.ends_with(b"\n") {
            writeln!(file)?;
        }

        writeln!(file, "\n--- PARSED STRUCT (After Processing) ---")?;
        writeln!(file, "Method: {}", self.method)?;
        writeln!(file, "Path: {}", self.path)?;
        writeln!(file, "Headers (normalized):")?;
        for (key, value) in &self.headers {
            writeln!(file, "  {}: {}", key, value)?;
        }
        writeln!(file, "Body: {}", self.body)?;

        writeln!(file, "\n--- TRANSFORMATIONS APPLIED ---")?;
        writeln!(file, "✓ Header keys: lowercased")?;
        writeln!(file, "✓ Header values: trimmed")?;
        writeln!(file, "✓ Path: validated (no ../ or //)")?;
        writeln!(
            file,
            "============================================================"
        )?;

        Ok(())
    }
}

fn validate_path_traversal(path: &str, base_canonical: &PathBuf) -> Result<(), String> {
    let requested = base_canonical.join(path.trim_start_matches('/'));

    let canonical = requested
        .canonicalize()
        .map_err(|_| "Invalid path or file not found".to_string())?;

    if !canonical.starts_with(&base_canonical) {
        return Err("Path traversal detected".to_string());
    }

    Ok(())
}
