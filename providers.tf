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
  }
}

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

provider "nsxt" {
  host     = var.nsxt_host
  username = var.nsxt_username
  password = var.nsxt_password
}

provider "vsphere" {
}