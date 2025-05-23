locals {
  # Defines core Google Cloud services that are enabled by default for any project created using this module.
  core_services = [
    "orgpolicy.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "iam.googleapis.com",
    "cloudasset.googleapis.com",
    "storage-api.googleapis.com",         # Required for Google Cloud Storage functionality.
    "storage-component.googleapis.com", # Required for Google Cloud Storage functionality.
    "compute.googleapis.com",           # Required for Compute Engine resources, including default service accounts.
    "serviceusage.googleapis.com",
    "logging.googleapis.com"
  ]

  all_services_to_enable = concat(local.core_services, var.custom_services)

  base_iams = {
    pubsubAdmin = {
      role   = "roles/pubsub.admin"
      member = "user:${var.tfrunner_user_email}"
    }
    bqAdmin = {
      role   = "roles/bigquery.admin"
      member = "user:${var.tfrunner_user_email}"
    }
  }
}

module "project" {
  source                = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project?ref=v36.1.0"
  billing_account       = var.billing_account_id
  name                  = var.project_id_suffix
  parent                = var.folder_id
  services              = local.all_services_to_enable
  iam_bindings_additive = local.base_iams # Applies IAM bindings defined in this module's local block.
  org_policies = {
    "compute.requireOsLogin" = {
      rules = [{ enforce = var.enable_oslogin }] # OS Login configuration is controlled by a module variable.
    }
  }
}

# Grants the Dataproc Worker role to the default Compute Engine service account for the project.
resource "google_project_iam_member" "iam-bindings-default-project-compute-sa" {
  project = module.project.project_id
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${module.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [module.project]
}

# Manages the default service account for the project.
# Roles for this service account are typically granted from the root module
# or by passing them via variables if this module needs to grant roles on behalf of the SA.
module "project-default-service-accounts" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "sa-default"
}

# Manages the Cloud Build service account for the project.
# Roles for this service account are typically granted from the root module or passed in via variables.
module "project-cloudbuild-service-accounts" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "sabuild-default"
}
