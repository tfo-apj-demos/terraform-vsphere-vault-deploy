terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.4"
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
    server        = "172.21.15.150"
    key_name      = "hashicorp.local."
    key_algorithm = "RsaSha256"
    key_secret    = var.dns_zone_signing_key
  }
}