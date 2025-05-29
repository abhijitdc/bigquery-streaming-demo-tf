# Provider configuration is inherited from the root module

resource "random_string" "bucket_suffix" {
  length  = 6
  lower   = true
  upper   = false
  special = false
}

module "bucket" {
  source                   = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs?ref=v36.1.0"
  project_id               = var.project_id
  prefix                   = var.bucket_prefix
  name                     = "${var.bucket_prefix}-bucket-${random_string.bucket_suffix.result}" # Constructing name within module
  location                 = var.location
  public_access_prevention = var.public_access_prevention
  versioning               = var.enable_versioning
  labels                   = var.bucket_labels
  force_destroy            = true
}
