resource "kubernetes_persistent_volume_claim_v1" "db" {
  metadata {
    name      = "db-data"
    namespace = local.ns
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  # local-path storage binds when the first pod uses the claim
  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "db" {
  metadata {
    name      = "db"
    namespace = local.ns
  }
  spec {
    replicas = 1
    strategy {
      type = "Recreate" # one writer for the volume at a time
    }
    selector {
      match_labels = { app = "db" }
    }
    template {
      metadata {
        labels = { app = "db" }
      }
      spec {
        container {
          name  = "mysql"
          image = "mysql:8.4"
          env {
            name  = "MYSQL_RANDOM_ROOT_PASSWORD"
            value = "yes"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "motd"
          }
          env {
            name  = "MYSQL_USER"
            value = "motd"
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db.metadata[0].name
                key  = "password"
              }
            }
          }
          port {
            container_port = 3306
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/mysql"
          }
          volume_mount {
            name       = "seed"
            mount_path = "/docker-entrypoint-initdb.d"
            read_only  = true
          }
          readiness_probe {
            exec {
              command = ["mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
            }
            period_seconds = 5
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.db.metadata[0].name
          }
        }
        volume {
          name = "seed"
          config_map {
            name = kubernetes_config_map_v1.seed.metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
  }
}

resource "kubernetes_service_v1" "db" {
  metadata {
    name      = "db"
    namespace = local.ns
  }
  spec {
    selector = { app = "db" }
    port {
      port = 3306
    }
  }
}
