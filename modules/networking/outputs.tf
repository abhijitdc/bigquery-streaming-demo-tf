output "vpc_name" {
  description = "The name of the created VPC."
  value       = module.my-vpc.name
}

output "vpc_self_link" {
  description = "The self-link of the created VPC."
  value       = module.my-vpc.self_link
}

output "subnet_name" {
  description = "The name of the primary subnet created."
  # Accessing the specific subnet created. The CFF module outputs a map of subnets.
  # We need to construct the key based on how it's named in the module.
  # Assuming the first subnet in the list is the one we want to output,
  # and its key in the output map is like "region/subnet_name".
  # This might need adjustment if the fabric module's output structure is different
  # or if multiple subnets are created. For a single subnet as defined:
  value       = module.my-vpc.subnets_names[0] # More robust if there's only one
  # or module.my-vpc.subnets["${var.resource_location}/${var.subnet_name}"].name if key is known
}

output "subnet_self_link" {
  description = "The self-link of the primary subnet created."
  value       = module.my-vpc.subnets_self_links[0] # More robust if there's only one
  # or module.my-vpc.subnets["${var.resource_location}/${var.subnet_name}"].self_link
}

output "subnet_region" {
  description = "The region of the primary subnet."
  value       = var.resource_location # Directly from variable as it defines the subnet's region
}
