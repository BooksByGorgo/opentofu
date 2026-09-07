output "public_ip" {
  value = oci_core_instance.motd.public_ip
}

output "fqdn" {
  value = local.fqdns[0]
}

output "certificate_pem" {
  value = acme_certificate.motd.certificate_pem
}

output "issuer_pem" {
  value = acme_certificate.motd.issuer_pem
}

output "private_key_pem" {
  value     = acme_certificate.motd.private_key_pem
  sensitive = true
}
