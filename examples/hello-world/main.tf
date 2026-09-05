terraform {
  required_version = ">= 1.6"
}

variable "greeting" {
  type        = string
  description = "What the program prints."
  default     = "hello world"

  validation {
    condition     = length(trimspace(var.greeting)) > 0
    error_message = "greeting must not be blank."
  }
}

resource "terraform_data" "hello" {
  input            = var.greeting
  triggers_replace = [var.greeting]

  provisioner "local-exec" {
    command = "echo '${self.input}'"
  }
}

output "greeting" {
  description = "What was printed."
  value       = terraform_data.hello.output
}
