terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.4.0"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.5"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1.1"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4"
    }
  }
}

provider "boundary" {
  addr = var.boundary_address
  auth_method_id         = var.service_account_authmethod_id
  auth_method_login_name = var.service_account_name
  auth_method_password   = var.service_account_password
}

provider "dns" {
  update {
    server = var.dns_server # Using the hostname is important in order for an SPN to match
    gssapi {
      realm    = var.dns_realm
      username = var.dns_username
      password = var.dns_password
    }
  }
}

provider "nsxt" {
  max_retries = 3
}

provider "vsphere" {
}

provider "vault" {
  address = var.vault_address
}