locals {
  fqdns = [for h in var.hostnames : "${h}.${var.domain}"]
}

resource "cloudflare_dns_record" "motd" {
  for_each = toset(local.fqdns)

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "A"
  content = oci_core_instance.motd.public_ip
  ttl     = 60
  proxied = false
}
