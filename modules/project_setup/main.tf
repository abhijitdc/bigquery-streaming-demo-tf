locals {
  # Define services and IAM policies that are core to this project setup module
  # These were previously in the root main.tf's local block
  core_services = [
    "orgpolicy.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "iam.googleapis.com",
    "cloudasset.googleapis.com",
    "storage-api.googleapis.com", # Often needed with project
    "storage-component.googleapis.com", # Often needed with project
    "compute.googleapis.com", # Often needed for default SA
    "serviceusage.googleapis.com",
    "logging.googleapis.com"
    # Add other essential services if they are always part of this project setup
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
    # Add other essential IAM bindings if they are always part of this project setup
  }
}

module "project" {
  source                = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project?ref=v36.1.0"
  billing_account       = var.billing_account_id
  name                  = var.project_id_suffix # Changed from var.project_id in root
  parent                = var.folder_id
  services              = local.all_services_to_enable
  iam_bindings_additive = local.base_iams # Using the local block from this module
  org_policies = {
    "compute.requireOsLogin" = {
      rules = [{ enforce = var.enable_oslogin }] # Controlled by module variable
    }
    # Add other common org policies here if desired, controlled by variables
  }
}

# Grants the required IAM permissions role to the default Compute Engine service account for the project.
resource "google_project_iam_member" "iam-bindings-default-project-compute-sa" {
  project = module.project.project_id
  role    = "roles/dataproc.worker" # This role seems specific, consider making it a variable
  member  = "serviceAccount:${module.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [module.project]
}

# Manages the default service account for the project.
module "project-default-service-accounts" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "sa-default" # Consider making this configurable via a variable
  # non-authoritative roles granted *to* the service accounts on other resources
  # These roles are project specific and will be defined when this module is called from root,
  # or passed in as a variable if this module needs to grant roles on behalf of the SA.
  # For now, keeping it simple. If this SA needs roles on this project, they can be added here.
  # Example:
  # iam_project_roles = {
  #   "${module.project.project_id}" = [
  #     "roles/logging.logWriter" # Example role for the default SA on its own project
  #   ]
  # }
}

# Manages the Cloud Build service account for the project.
module "project-cloudbuild-service-accounts" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "sabuild-default" # Consider making this configurable
  # Similar to default SA, roles are granted from root or passed in.
}
