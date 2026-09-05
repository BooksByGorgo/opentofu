locals {
  shape = "VM.Standard.E2.1.Micro" # always free: 1 OCPU, 1 GB
  ads   = data.oci_identity_availability_domains.ads.availability_domains
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "motd" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ads[var.ad_index].name
  display_name        = "motd"
  shape               = local.shape

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "motd"
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key))
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }
}
