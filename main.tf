# --- Get latest Vault image value from HCP Packer
data "hcp_packer_artifact" "this" {
  bucket_name  = "vault-ubuntu-2204"
  channel_name = "latest"
  platform     = "vsphere"
  region       = "Datacenter"
}

# --- Retrieve IPs for use by the load balancer and Vault virtual machines
data "nsxt_policy_ip_pool" "this" {
  display_name = "10 - gcve-foundations"
}
resource "nsxt_policy_ip_address_allocation" "this" {
  count        = var.vault_cluster_size
  display_name = "vault-blue-${count.index}"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

resource "nsxt_policy_ip_address_allocation" "load_balancer" {
  display_name = "vault-load-balancer"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

# --- Generate a Vault token for the agent to bootstrap and retrieve certificates for the Vault server
resource "vault_token" "this" {
  count     = var.vault_cluster_size
  no_parent = true
  period    = "24h"
  policies = [
    "vault_unseal",
    "generate_certificate"
  ]
}

# --- Deploy Load Balancer
module "load_balancer" {
  source  = "app.terraform.io/tfo-apj-demos/load-balancer/nsxt"
  version = "0.0.1"

  hosts = [for hostname, address in zipmap(module.vault_blue.*.virtual_machine_name, module.vault_blue.*.ip_address) : { "hostname" = hostname, "address" = address }]
  ports = [
    "8200"
  ]
  load_balancer_ip_address = nsxt_policy_ip_address_allocation.load_balancer.allocation_ip
  name                     = "vault"
  lb_app_profile_type      = "TCP"
}

# --- Deploy a cluster of Vault nodes
module "vault_blue" {
  source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "~> 1.4"

  count = var.vault_cluster_size

  hostname          = "vault-blue-${count.index + 1}"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "Demo Management"
  resource_pool     = "Demo Management"
  networks = {
    "seg-general" : "${nsxt_policy_ip_address_allocation.this[count.index].allocation_ip}/22"
  }
  dns_server_list = [
    "172.21.15.150",
    "10.10.0.8"
  ]
  gateway         = "172.21.12.1"
  dns_suffix_list = ["hashicorp.local"]


  template = data.hcp_packer_artifact.this.external_identifier
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
    vault_agent_config = base64encode(templatefile("${path.module}/templates/vault_agent.conf.tmpl", {
      hostname               = "vault-blue-${count.index + 1}"
      vault_address          = var.vault_address
      private_ip             = nsxt_policy_ip_address_allocation.this[count.index].allocation_ip
      load_balancer_ip       = nsxt_policy_ip_address_allocation.load_balancer.allocation_ip
      load_balancer_dns_name = var.load_balancer_dns_name
    }))
    ip_address = nsxt_policy_ip_address_allocation.this[count.index].allocation_ip
  })
}

# --- Create Boundary targets for the Vault nodes
module "boundary_target" {
  source  = "app.terraform.io/tfo-apj-demos/target/boundary"
  version = "~> 1"

  hosts = [for hostname, address in zipmap(module.vault_blue.*.virtual_machine_name, module.vault_blue.*.ip_address) : { "hostname" = hostname, "address" = address }]
  services = [
    {
      name = "ssh",
      type = "ssh",
      port = "22"
    }
  ]

  project_name  = "gcve_admins"
  hostname_prefix = "vault_blue"
  #host_catalog_id = "hcst_RACKlVym4Z"
  #injected_credential_library_ids = ["clvsclt_bDETPnhh75"]
  boundary_credential_store_vault_name = "HCP Vault"
  vault_address = "https://production.vault.11eb56d6-0f95-3a99-a33c-0242ac110007.aws.hashicorp.cloud:8200/"
}

# --- Add Vault nodes and LB to DNS
module "domain-name-system-management" {
  source  = "app.terraform.io/tfo-apj-demos/domain-name-system-management/dns"
  version = "~> 1.0"

  a_records = concat(
    [{
      name      = var.load_balancer_dns_name
      addresses = [nsxt_policy_ip_address_allocation.load_balancer.allocation_ip]
    }],
    [for i in range(var.vault_cluster_size) : {
      name      = module.vault_blue[i].virtual_machine_name
      addresses = [module.vault_blue[i].ip_address]
    }]
  )
}

# locals {
#   filter = var.operator == "contains" ?   : "${jsonencode(var.tag_value)} ${var.operator} ${jsonencode(var.tag_key)}"
# }