variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to build in; the tenancy OCID works."
}

variable "ad_index" {
  type        = number
  description = "Which availability domain to use; try another if you are out of capacity."
  default     = 0
}

variable "ssh_public_key" {
  type        = string
  description = "Path to the SSH public key that may log in as ubuntu."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "admin_cidr" {
  type        = string
  description = "Who may reach SSH; narrow this to your own address."
  default     = "0.0.0.0/0"
}

variable "domain" {
  type        = string
  description = "DNS zone managed in Cloudflare, e.g. example.com."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Zone ID of the domain, from the Cloudflare dashboard."
}

variable "hostnames" {
  type        = list(string)
  description = "Host names under the domain; the first is the certificate's common name."
  default     = ["motd"]

  validation {
    condition     = length(var.hostnames) > 0
    error_message = "at least one host name is needed."
  }
}

variable "acme_email" {
  type        = string
  description = "Contact address for the Let's Encrypt account."
}

variable "acme_server" {
  type        = string
  description = "ACME directory; switch to production once everything works."
  default     = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
