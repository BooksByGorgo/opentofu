locals {
  app_dir = "${path.module}/app"
  # changes whenever any file under app/ changes
  app_hash = sha1(join("", [for f in fileset(local.app_dir, "**") :
    filesha1("${local.app_dir}/${f}")
  ]))
}

resource "docker_image" "web" {
  name = "motd:ch2"

  build {
    context = local.app_dir
  }

  triggers = {
    src = local.app_hash
  }
}

resource "docker_container" "web" {
  name  = "motd"
  image = docker_image.web.image_id

  ports {
    internal = 8080
    external = var.port
  }
}

check "hello" {
  data "http" "web" {
    url = "http://localhost:${docker_container.web.ports[0].external}/"

    retry {
      attempts     = 5
      min_delay_ms = 1000
    }
  }

  assert {
    condition     = trimspace(data.http.web.response_body) == "Hello, World!"
    error_message = "the web server did not say hello"
  }
}

output "url" {
  value = "http://localhost:${var.port}/"
}
