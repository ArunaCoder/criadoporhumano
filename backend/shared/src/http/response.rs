pub struct HttpResponse {
    status_code: u16,
    status_text: &'static str,
    current_type: &'static str,
    body: String,
}

impl HttpResponse {
    pub fn new(body: String) -> Self {
        Self {
            status_code: 200,
            status_text: "OK",
            current_type: "application/json",
            body,
        }
    }
}
