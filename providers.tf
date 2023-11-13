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
  }
}

provider "vsphere" {}

provider "nsxt" {}

provider "boundary" {
  addr  = var.boundary_addr
  token = var.boundary_token
}
