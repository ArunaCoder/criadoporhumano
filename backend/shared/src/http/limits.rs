pub const MAX_LINE_SIZE: usize = 2048;
pub const MAX_HEADERS: usize = 100;
pub const MAX_BODY_SIZE: usize = 8192;
pub const READ_TIMEOUT_SECS: u64 = 5;
pub const WRITE_TIMEOUT_SECS: u64 = 5;

pub const ALLOWED_METHODS: &[&str] = &["GET", "POST", "HEAD", "OPTIONS"];
