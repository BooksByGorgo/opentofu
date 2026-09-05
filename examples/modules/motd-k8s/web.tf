resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "web"
    namespace = local.ns
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "web" }
    }
    template {
      metadata {
        labels = { app = "web" }
      }
      spec {
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret == null ? [] : [var.image_pull_secret]
          content {
            name = image_pull_secrets.value
          }
        }
        container {
          name  = "web"
          image = var.image
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db.metadata[0].name
                key  = "password"
              }
            }
          }
          env {
            name  = "DB_DSN" # kubernetes expands $(DB_PASSWORD) at start
            value = "motd:$(DB_PASSWORD)@tcp(db:3306)/motd"
          }
          env {
            name  = "TZ"
            value = var.timezone
          }
          port {
            container_port = 8080
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            period_seconds = 5
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
  }

  depends_on = [kubernetes_service_v1.db]
}

resource "kubernetes_service_v1" "web" {
  metadata {
    name      = "web"
    namespace = local.ns
  }
  spec {
    type     = var.node_port == null ? "ClusterIP" : "NodePort"
    selector = { app = "web" }
    port {
      port        = 8080
      target_port = 8080
      node_port   = var.node_port
    }
  }
}
