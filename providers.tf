terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.2"
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
  }
  cloud {
    organization = "tfo-apj-demos"
    workspaces {
      name = "vsphere-vault"
    }
  }
}

provider "nsxt" {}

provider "boundary" {
  addr  = var.boundary_addr
  token = var.boundary_token
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