module "sayings" {
  source = "github.com/BooksByGorgo/opentofu//tasting/examples/motd?ref=main"
}

locals {
  app_dir = "${path.module}/app"
  app_hash = sha1(join("", [for f in fileset(local.app_dir, "**") :
    filesha1("${local.app_dir}/${f}")
  ]))
  # the tag names the source, so a new build is a new image name
  image = "motd:${substr(local.app_hash, 0, 12)}"
}

resource "docker_image" "web" {
  name = local.image

  build {
    context = local.app_dir
  }
}

# kind cannot pull from the local docker daemon, so copy the image in
resource "terraform_data" "kind_load" {
  triggers_replace = [docker_image.web.image_id]

  provisioner "local-exec" {
    command = "kind load docker-image ${docker_image.web.name} --name motd"
  }
}

resource "random_password" "db" {
  length  = 24
  special = false
}

module "motd" {
  source = "../modules/motd-k8s"

  image       = docker_image.web.name
  seed_sql    = module.sayings.sql
  db_password = random_password.db.result
  timezone    = var.timezone
  node_port   = 30080

  depends_on = [terraform_data.kind_load]
}

check "saying" {
  data "http" "web" {
    url = "http://localhost:${var.port}/"

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

output "namespace" {
  value = module.motd.namespace
}
