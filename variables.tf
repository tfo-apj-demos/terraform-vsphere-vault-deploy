## Provider details
# It's easier using TF vars for the Boundary provider.

variable "boundary_address" {
  type = string
}

variable "service_account_authmethod_id" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "service_account_password" {
  type = string
}

## Vault deployment variables
variable "vault_license" {
  type = string
}

variable "vault_cluster_size" {
  type    = number
  default = 3
}

variable "vault_address" {
  type        = string
  description = "The address of the upstream HCP Vault server that is used for unseal."
}

variable "vault_vsphere_user" {
  type = string
}

variable "vault_vsphere_password" {
  type = string
}

variable "vault_vsphere_host" {
  type = string
}

## Boundary variables to add Vault as a target in Boundary
variable "scope_id" {
  default = "p_0tEkEaHvJl"
}

variable "credential_library_id" {
  default = "clvsclt_gmitu8xc09"
}

variable "host_catalog_id" {
  default = "hcst_7B2FWBRqb0"
}

## These aren't yet used, just in place for some future work on the Boundary target module
variable "tag_value" {
  default = "vmware"
}

variable "tag_key" {
  default = "/tags/platform"
}

variable "operator" {
  default = "in"
}

variable "dns_username" {
  type = string
}

variable "dns_password" {
  type = string
}

variable "dns_realm" {
  type = string
}

variable "dns_server" {
  type = string
}

variable "load_balancer_dns_name" {
  type = string
}