output "network" {
  description = "Docker network the containers share."
  value       = docker_network.motd.name
}

output "web_container" {
  description = "Name of the web container, reachable on the network at port 8080."
  value       = docker_container.web.name
}
