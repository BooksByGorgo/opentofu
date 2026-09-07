variable "namespace" {
  type        = string
  description = "Namespace that holds everything."
  default     = "motd"
}

variable "image" {
  type        = string
  description = "Web server image, e.g. motd:abc123."
}

variable "image_pull_secret" {
  type        = string
  description = "Name of a registry pull secret in the namespace, if the image needs one."
  default     = null
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
  description = "Time zone the server uses to pick the current saying."
  default     = "America/Los_Angeles"
}

variable "node_port" {
  type        = number
  description = "Publish the web server on this NodePort; null means ClusterIP only."
  default     = null
}
