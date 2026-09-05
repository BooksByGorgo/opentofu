terraform {
  required_version = ">= 1.6"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "oci" {
  # reads ~/.oci/config, written by `oci setup config`
}

provider "cloudflare" {
  # reads CLOUDFLARE_API_TOKEN
}

provider "acme" {
  server_url = var.acme_server
}
