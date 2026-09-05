resource "github_repository" "motd" {
  name        = "motd"
  description = "message of the day web server"
  visibility  = "public"
}

output "clone_url" {
  value = github_repository.motd.ssh_clone_url
}
