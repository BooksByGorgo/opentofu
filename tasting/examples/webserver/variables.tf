variable "port" {
  type        = number
  description = "Host port the web server is published on."
  default     = 8080

  validation {
    condition     = var.port > 1024 && var.port < 65536
    error_message = "port must be an unprivileged port (1025-65535)."
  }
}
