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
  value       = module.my-vpc.subnets["${var.resource_location}/${var.subnet_name}"].name
}

output "subnet_self_link" {
  description = "The self-link of the primary subnet created."
  value       = module.my-vpc.subnets["${var.resource_location}/${var.subnet_name}"].self_link
}

output "subnet_region" {
  description = "The region of the primary subnet."
  value       = var.resource_location
}
