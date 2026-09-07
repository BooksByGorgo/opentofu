resource "terraform_data" "hello" {
  provisioner "local-exec" {
    command = "echo hello world"
  }
}
