provider "docker" {
  # talks to the local docker daemon; set host for a remote one, e.g.
  # host = "ssh://ubuntu@my-server"
}

provider "github" {
  # reads the token from the GITHUB_TOKEN environment variable
}
