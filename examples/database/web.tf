locals {
  app_dir = "${path.module}/app"
  app_hash = sha1(join("", [for f in fileset(local.app_dir, "**") :
    filesha1("${local.app_dir}/${f}")
  ]))
}

resource "docker_image" "web" {
  name = "motd:ch3"

  build {
    context = local.app_dir
  }

  triggers = {
    src = local.app_hash
  }
}

resource "docker_container" "web" {
  name  = "motd-web"
  image = docker_image.web.image_id

  env = [
    "DB_DSN=motd:${random_password.db.result}@tcp(db:3306)/motd",
    "TZ=${var.timezone}",
  ]

  networks_advanced {
    name = docker_network.motd.name
  }

  ports {
    internal = 8080
    external = var.port
  }

  depends_on = [docker_container.db]
}

check "saying" {
  data "http" "web" {
    url = "http://localhost:${docker_container.web.ports[0].external}/"

    retry {
      attempts     = 5
      min_delay_ms = 2000
    }
  }

  assert {
    condition = can(regex(
      "^\\[\\d\\d:\\d\\d:\\d\\d\\] .+", data.http.web.response_body
    ))
    error_message = "not a saying: ${data.http.web.response_body}"
  }
}

output "url" {
  value = "http://localhost:${var.port}/"
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
