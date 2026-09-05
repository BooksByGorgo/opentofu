resource "tls_private_key" "account" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "acme_registration" "motd" {
  account_key_pem = tls_private_key.account.private_key_pem
  email_address   = var.acme_email
}

resource "acme_certificate" "motd" {
  account_key_pem           = acme_registration.motd.account_key_pem
  common_name               = local.fqdns[0]
  subject_alternative_names = slice(local.fqdns, 1, length(local.fqdns))

  dns_challenge {
    provider = "cloudflare" # reads CLOUDFLARE_DNS_API_TOKEN
  }
}
