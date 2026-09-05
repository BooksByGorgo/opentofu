variable "app_dir" {
  type        = string
  description = "Directory holding the web server source and Dockerfile."
}

variable "seed_sql" {
  type        = string
  description = "SQL that creates and fills the sayings table."
}

variable "db_password" {
  type        = string
  description = "Password for the motd database user."
  sensitive   = true
}

variable "timezone" {
  type        = string
  description = "Time zone the server uses to pick the saying of the second."
  default     = "America/Los_Angeles"
}

variable "port" {
  type        = number
  description = "Host port to publish the web server on; null publishes nothing."
  default     = null
}
