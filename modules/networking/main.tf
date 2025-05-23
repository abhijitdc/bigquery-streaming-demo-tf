# Provider configuration is inherited from the root module

module "my-vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc?ref=v36.1.0"
  project_id = var.project_id
  name       = var.vpc_name
  subnets = [
    {
      name                  = var.subnet_name
      region                = var.resource_location
      ip_cidr_range         = var.subnet_ip_cidr_range
      description           = var.subnet_description
      enable_private_access = true # Assuming this is generally desired for this subnet
    }
  ]
}

module "my-vpc-firewall" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc-firewall?ref=v36.1.0"
  project_id = var.project_id
  network    = module.my-vpc.name # Reference the VPC created in this module
  default_rules_config = {
    admin_ranges = var.firewall_admin_ranges
  }
  ingress_rules = {
    # Example rule name, can be made more dynamic if needed
    "allow-custom-ingress" = {
      description   = "Allow custom ingress based on module variables."
      source_ranges = var.firewall_ingress_source_ranges
      # Fabric module might require actual lists for sources/targets, not just strings if multiple
      sources       = var.firewall_ingress_sources_tags_or_sa 
      targets       = var.firewall_ingress_target_tags_or_sa
    }
  }
}

module "nat" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-cloudnat?ref=v36.1.0"
  project_id     = var.project_id
  region         = var.resource_location # Assumes NAT is in the same region as the subnet
  name           = var.nat_name
  router_network = module.my-vpc.self_link # Reference the VPC created in this module
}
