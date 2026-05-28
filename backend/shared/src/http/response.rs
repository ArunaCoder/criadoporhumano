pub struct HttpResponse {
    status_code: u16,
    status_text: &'static str,
    content_type: &'static str,
    body: String,
}

impl HttpResponse {
    pub fn ok(body: String) -> Self {
        Self {
            status_code: 200,
            status_text: "OK",
            content_type: "application/json",
            body,
        }
    }

    pub fn not_found() -> Self {
        Self {
            status_code: 404,
            status_text: "Not Found",
            content_type: "application/json",
            body: r#"{"error": "Not Found"}"#.to_string(),
        }
    }
    pub fn bad_request() -> Self {
        Self {
            status_code: 400,
            status_text: "Bad Request",
            content_type: "application/json",
            body: r#"{"error": "Bad Request"}"#.to_string(),
        }
    }
    pub fn server_error() -> Self {
        Self {
            status_code: 500,
            status_text: "Server Error",
            content_type: "application/json",
            body: r#"{"error": "Server Error"}"#.to_string(),
        }
    }
    pub fn to_bytes(&self) -> Vec<u8> {
        format!(
            "HTTP/1.1 {} {}\r\nContent-Type: {}\r\nContent-Length: {} \r\n\r\n{}",
            self.status_code,
            self.status_text,
            self.content_type,
            self.body.len(),
            self.body
        )
        .into_bytes()
    }
}
