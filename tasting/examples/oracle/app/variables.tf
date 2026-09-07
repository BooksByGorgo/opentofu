variable "docker_host" {
  type        = string
  description = "Docker host to deploy to; null means the VM from the infra stage."
  default     = null
}

variable "timezone" {
  type        = string
  description = "Time zone the server uses to pick the current saying."
  default     = "America/Los_Angeles"
}

variable "http_port" {
  type    = number
  default = 80
}

variable "https_port" {
  type    = number
  default = 443
}
