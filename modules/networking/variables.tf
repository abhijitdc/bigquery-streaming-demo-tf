variable "project_id" {
  type        = string
  description = "The ID of the project where networking resources will be created."
}

variable "resource_location" {
  type        = string
  description = "The GCP region for networking resources, e.g., 'us-central1'."
}

variable "vpc_name" {
  type        = string
  description = "The name for the VPC network."
  default     = "main-vpc"
}

variable "subnet_name" {
  type        = string
  description = "The name for the subnet."
  default     = "default-subnet"
}

variable "subnet_ip_cidr_range" {
  type        = string
  description = "The IP CIDR range for the subnet."
  default     = "10.0.1.0/24"
}

variable "subnet_description" {
  type        = string
  description = "Description for the subnet."
  default     = "Default subnet"
}

variable "firewall_admin_ranges" {
  type        = list(string)
  description = "List of IP CIDR ranges for admin access in default firewall rules."
  default     = ["10.0.1.0/24"] # Defaulting to the current value in main.tf
}

variable "firewall_ingress_source_ranges" {
  type        = list(string)
  description = "List of source IP CIDR ranges for custom ingress rules."
  default     = ["10.0.1.0/24"] # Defaulting to the current value in main.tf
}

variable "firewall_ingress_sources_tags_or_sa" {
  type        = list(string)
  description = "List of source tags or service accounts for custom ingress rules."
  default     = ["dataflow"] # Defaulting to the current value in main.tf
}

variable "firewall_ingress_target_tags_or_sa" {
  type        = list(string)
  description = "List of target tags or service accounts for custom ingress rules."
  default     = ["dataflow"] # Defaulting to the current value in main.tf
}

variable "nat_name" {
  type        = string
  default     = "default-nat"
  description = "Name for the Cloud NAT gateway."
}
