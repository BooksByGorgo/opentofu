terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_namespace_v1" "motd" {
  metadata {
    name = var.namespace
  }
}

locals {
  ns = kubernetes_namespace_v1.motd.metadata[0].name
}

resource "kubernetes_secret_v1" "db" {
  metadata {
    name      = "db"
    namespace = local.ns
  }
  data = {
    password = var.db_password
  }
}

resource "kubernetes_config_map_v1" "seed" {
  metadata {
    name      = "db-seed"
    namespace = local.ns
  }
  data = {
    "001-sayings.sql" = var.seed_sql
  }
}
