output "namespace" {
  value = local.ns
}

output "web_service" {
  description = "Name of the web service inside the namespace."
  value       = kubernetes_service_v1.web.metadata[0].name
}
