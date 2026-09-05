terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_network" "motd" {
  name = "motd"
}

# a resource stands in for the seed so the volume can watch it for changes
resource "terraform_data" "seed" {
  input = var.seed_sql
}

resource "docker_volume" "db_data" {
  name = "motd-db-data"

  lifecycle {
    # the seed only loads into an empty volume, so new seed => new volume
    replace_triggered_by = [terraform_data.seed]
  }
}

resource "docker_image" "mysql" {
  name = "mysql:8.4"
}

resource "docker_container" "db" {
  name  = "motd-db"
  image = docker_image.mysql.image_id

  env = [
    "MYSQL_RANDOM_ROOT_PASSWORD=yes",
    "MYSQL_DATABASE=motd",
    "MYSQL_USER=motd",
    "MYSQL_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name    = docker_network.motd.name
    aliases = ["db"]
  }

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/mysql"
  }

  # copied into the container at creation, wherever the docker host is
  upload {
    content = var.seed_sql
    file    = "/docker-entrypoint-initdb.d/001-sayings.sql"
  }

  healthcheck {
    test     = ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
    interval = "5s"
    timeout  = "3s"
    retries  = 3
  }
  wait         = true
  wait_timeout = 300

  lifecycle {
    replace_triggered_by = [docker_volume.db_data]
  }
}

locals {
  app_hash = sha1(join("", [for f in fileset(var.app_dir, "**") :
    filesha1("${var.app_dir}/${f}")
  ]))
}

resource "docker_image" "web" {
  name = "motd:${substr(local.app_hash, 0, 12)}"

  build {
    context = var.app_dir
  }
}

resource "docker_container" "web" {
  name  = "motd-web"
  image = docker_image.web.image_id

  env = [
    "DB_DSN=motd:${var.db_password}@tcp(db:3306)/motd",
    "TZ=${var.timezone}",
  ]

  networks_advanced {
    name = docker_network.motd.name
  }

  dynamic "ports" {
    for_each = var.port == null ? [] : [var.port]
    content {
      internal = 8080
      external = ports.value
    }
  }

  depends_on = [docker_container.db]
}
