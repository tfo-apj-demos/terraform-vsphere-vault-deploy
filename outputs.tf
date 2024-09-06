output "vault_address" {
  value = nsxt_policy_ip_address_allocation.load_balancer.allocation_ip
}
/*
output "existing_ssh_credential_library_ids_output" {
  value = module.boundary_target.existing_ssh_credential_library_ids
}

output "service_keys_output" {
  value = module.boundary_target.service_keys
}

output "host_catalog_id" {
  value = module.boundary_target.host_catalog_id
}

output "host_ids" {
  value = module.boundary_target.host_ids
}*/