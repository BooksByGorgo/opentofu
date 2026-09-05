resource "github_repository" "motd" {
  name        = "tasting-tofu-motd"
  description = "message of the day web server"
  visibility  = "private"
}

output "clone_url" {
  value = github_repository.motd.ssh_clone_url
}
