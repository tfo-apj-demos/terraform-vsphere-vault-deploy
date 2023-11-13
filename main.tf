data "hcp_packer_image" "this" {
  bucket_name    = "vault-ubuntu-2204"
  channel        = "latest"
  cloud_provider = "vsphere"
  region         = "Datacenter"
}

resource "vault_token" "this" {
  count     = var.vault_cluster_size
  no_parent = true
  period    = "24h"
  policies = [
    "vault_unseal",
    "generate_certificate"
  ]
}

# resource "nsxt_policy_lb_pool" "this" {
#   display_name       = "vault"
#   min_active_members = 1
#   dynamic "member" {
#     for_each = module.vault_blue
#     content {
#       admin_state                = "ENABLED"
#       backup_member              = false
#       display_name               = each.value.virtual_machine_name
#       ip_address                 = each.value.ip_address
#       max_concurrent_connections = 12
#       port                       = "8200"
#       weight                     = 1
#     }
#   }
#   snat {
#     type = "AUTOMAP"
#   }
# }

module "vault_blue" {
  source = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "~> 1.3"

  count = var.vault_cluster_size

  hostname          = "vault-blue-${count.index + 1}"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "management"
  networks = {
    "seg-general" : "dhcp"
  }
  template = data.hcp_packer_image.this.cloud_image_id
  tags = {
    "application" = "vault-server"
  }

  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    hostname               = "vault-blue-${count.index + 1}"
    vault_address          = var.vault_address
    vault_token            = vault_token.this[count.index].client_token
    vault_license          = var.vault_license
    vault_vsphere_host     = var.vault_vsphere_host
    vault_vsphere_user     = var.vault_vsphere_user
    vault_vsphere_password = var.vault_vsphere_password
    vault_agent_config     = base64encode(templatefile("${path.module}/templates/vault_agent.conf.tmpl", {
      hostname      = "vault-blue-${count.index + 1}"
      vault_address = var.vault_address
    }))
  })

  metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
    hostname = "vault-blue-${count.index + 1}"
  })
}

### Boundary
resource "boundary_host_static" "this" {
  count           = length(module.vault_blue)
  type            = "static"
  name            = module.vault_blue[count.index].virtual_machine_name
  host_catalog_id = var.host_catalog_id
  address         = module.vault_blue[count.index].ip_address
}

resource "boundary_host_set_static" "this" {
  type            = "static"
  name            = "vault_servers"
  host_catalog_id = var.host_catalog_id

  host_ids = boundary_host_static.this.*.id
}

resource "boundary_target" "ssh_this" {
  name         = "ssh_vault_blue"
  type         = "ssh"
  default_port = "22"
  scope_id     = var.scope_id
  host_source_ids = [
    boundary_host_set_static.this.id
  ]
  injected_application_credential_source_ids = [
    var.credential_library_id
  ]
  ingress_worker_filter = "\"vmware\" in \"/tags/platform\""
}



# locals {
#   filter = var.operator == "contains" ?   : "${jsonencode(var.tag_value)} ${var.operator} ${jsonencode(var.tag_key)}"
# }

# module "remote_access" {
#   source = "./modules/remote_access"

#   host_catalog_id = ""
#   credential_library_id = ""
#   scope_id = ""
#   targets = [
#     {
#       type = "ssh"
#       port = 22
#     }
#     {

#     }
#   ]
# }

# variable "remote_access" {
#   type = list(object({
#     type = string
#     port = number
#   }))
# }


# 172.21.12.1/22
# 172.21.12.10-172.21.15.199
# 172.21.12.200-172.21.12.253
# jsonencode(""vmware" in "/tags/platform""")
