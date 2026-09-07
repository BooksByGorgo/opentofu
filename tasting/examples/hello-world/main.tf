terraform {
  required_version = ">= 1.6" # OpenTofu 1.6, Terraform 1.6, or newer
}

variable "greeting" {
  type        = string
  description = "What the program prints."
  default     = "hello world" # remove this line to make the greeting required

  validation {
    condition     = length(trimspace(var.greeting)) > 0
    error_message = "greeting must not be blank."
  }
}

# a placeholder resource; running the provisioner is all it does
resource "terraform_data" "hello" {
  input            = var.greeting
  triggers_replace = [var.greeting] # a new greeting means a new resource

  provisioner "local-exec" {
    command = "echo '${self.input}'"
  }
}

output "greeting" {
  description = "What was printed."
  value       = terraform_data.hello.output
}
