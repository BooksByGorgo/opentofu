module "sayings" {
  source = "../../modules/sayings"
}

resource "random_password" "db" {
  length  = 24
  special = false
}

module "motd" {
  source = "../../modules/motd-docker"

  app_dir     = "${path.module}/app"
  seed_sql    = module.sayings.sql
  db_password = random_password.db.result
  timezone    = var.timezone
  # no host port: only the proxy talks to the web server
}

locals {
  caddyfile = <<-EOT
    ${local.infra.fqdn} {
        tls /certs/tls.crt /certs/tls.key
        reverse_proxy ${module.motd.web_container}:8080
    }
  EOT
}

resource "docker_image" "caddy" {
  name = "caddy:2"
}

resource "docker_container" "proxy" {
  name  = "motd-proxy"
  image = docker_image.caddy.image_id

  networks_advanced {
    name = module.motd.network
  }

  ports {
    internal = 80
    external = var.http_port
  }

  ports {
    internal = 443
    external = var.https_port
  }

  upload {
    content = local.caddyfile
    file    = "/etc/caddy/Caddyfile"
  }

  upload {
    content = "${local.infra.certificate_pem}${local.infra.issuer_pem}"
    file    = "/certs/tls.crt"
  }

  upload {
    content = sensitive(local.infra.private_key_pem)
    file    = "/certs/tls.key"
  }
}

check "saying" {
  data "http" "web" {
    url      = "https://${local.infra.fqdn}:${docker_container.proxy.ports[1].external}/"
    insecure = true # staging certificates are not trusted by anyone

    retry {
      attempts     = 5
      min_delay_ms = 2000
    }
  }

  assert {
    condition     = can(regex("^\\[\\d\\d:\\d\\d:\\d\\d\\] .+", data.http.web.response_body))
    error_message = "the web server did not serve a saying: ${data.http.web.response_body}"
  }
}

output "url" {
  value = "https://${local.infra.fqdn}/"
}
