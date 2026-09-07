variable "port" {
  type        = number
  description = "Host port the web server is published on."
  default     = 8080
}

variable "timezone" {
  type        = string
  description = "Time zone the server uses to pick the current saying."
  default     = "America/Los_Angeles"
}
