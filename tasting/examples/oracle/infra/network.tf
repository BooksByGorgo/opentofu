resource "oci_core_vcn" "motd" {
  compartment_id = var.compartment_ocid
  display_name   = "motd"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "motd"
}

resource "oci_core_internet_gateway" "motd" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.motd.id
  display_name   = "motd"
}

# every VCN comes with a default route table; take it over and add a route out
resource "oci_core_default_route_table" "motd" {
  manage_default_resource_id = oci_core_vcn.motd.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.motd.id
  }
}

locals {
  open_ports = {
    ssh   = { port = 22, source = var.admin_cidr }
    http  = { port = 80, source = "0.0.0.0/0" }
    https = { port = 443, source = "0.0.0.0/0" }
  }
}

resource "oci_core_default_security_list" "motd" {
  manage_default_resource_id = oci_core_vcn.motd.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # one ingress rule per entry in local.open_ports
  dynamic "ingress_security_rules" {
    for_each = local.open_ports
    content {
      protocol = "6" # tcp
      source   = ingress_security_rules.value.source
      tcp_options {
        min = ingress_security_rules.value.port
        max = ingress_security_rules.value.port
      }
    }
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.motd.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "public"
  dns_label      = "public"
}
