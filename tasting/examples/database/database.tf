resource "random_password" "db" {
  length  = 24
  special = false # keeps the password safe to paste into a DSN
}

resource "local_file" "seed" {
  filename = "${path.module}/seed/001-sayings.sql"
  content  = module.sayings.sql

  lifecycle {
    precondition {
      condition     = length(module.sayings.sayings) == 3600
      error_message = "need exactly 3600 sayings, one per second of the hour."
    }
  }
}

resource "docker_network" "motd" {
  name = "motd"
}

resource "docker_volume" "db_data" {
  name = "motd-db-data"

  lifecycle {
    # the seed only loads into an empty volume, so new seed => new volume
    replace_triggered_by = [local_file.seed]
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
    "MYSQL_PASSWORD=${random_password.db.result}",
  ]

  networks_advanced {
    name    = docker_network.motd.name
    aliases = ["db"]
  }

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/mysql"
  }

  volumes {
    host_path      = abspath(dirname(local_file.seed.filename))
    container_path = "/docker-entrypoint-initdb.d"
    read_only      = true
  }

  healthcheck {
    test     = ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
    interval = "5s"
    timeout  = "3s"
    retries  = 3
  }
  wait         = true # creation finishes when the health check passes
  wait_timeout = 180

  lifecycle {
    replace_triggered_by = [docker_volume.db_data]
  }
}
