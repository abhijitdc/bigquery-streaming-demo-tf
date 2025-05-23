provider "google" {
  user_project_override = true
  # billing_project might be needed if the user running terraform isn't the project owner
  # billing_project       = "dctoybox" # This was in the original, keep if necessary
}

# Variables are defined in variables.tf.
# No major locals needed here anymore, they are encapsulated in modules.

# Module 1: Project Setup (Foundation)
module "project_setup" {
  source   = "./modules/project_setup"

  tfrunner_user_email = var.tfrunner_user_email
  project_id_suffix   = var.project_id # The original var.project_id is used as the suffix/name here
  billing_account_id  = var.billing_account_id
  folder_id           = var.folder_id
  enable_oslogin      = false # Matches original "compute.requireOsLogin" = { rules = [{ enforce = false }] }
  
  # Example of adding custom services beyond the module's core list:
  # custom_services     = ["dataflow.googleapis.com", "notebooks.googleapis.com"] 
  # The core services list in the module already includes many of the original ones.
  # We need to ensure all originally listed services in local.services are covered
  # either in project_setup/main.tf's core_services or passed via custom_services.
  # Original services:
  # "orgpolicy.googleapis.com", "cloudresourcemanager.googleapis.com", "servicemanagement.googleapis.com",
  # "iam.googleapis.com", "cloudasset.googleapis.com", "storage-api.googleapis.com", "storage-component.googleapis.com",
  # "compute.googleapis.com", "dataflow.googleapis.com", "bigquery.googleapis.com", "bigquerystorage.googleapis.com",
  # "bigqueryconnection.googleapis.com", "bigquerydatatransfer.googleapis.com", "analyticshub.googleapis.com",
  # "notebooks.googleapis.com", "pubsub.googleapis.com", "artifactregistry.googleapis.com",
  # "cloudbuild.googleapis.com", "run.googleapis.com", "serviceusage.googleapis.com", "logging.googleapis.com"
  # The project_setup module has:
  # "orgpolicy.googleapis.com", "cloudresourcemanager.googleapis.com", "servicemanagement.googleapis.com", "iam.googleapis.com",
  # "cloudasset.googleapis.com", "storage-api.googleapis.com", "storage-component.googleapis.com", "compute.googleapis.com",
  # "serviceusage.googleapis.com", "logging.googleapis.com"
  # So, we need to pass the rest via custom_services:
  custom_services = [
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "analyticshub.googleapis.com",
    "notebooks.googleapis.com",
    "pubsub.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com"
  ]
}

# IAM bindings for the service accounts created in project_setup
# These were previously defined in the CFF iam-service-account modules directly.
# Now, we apply them at the root level to the SAs produced by project_setup.

resource "google_project_iam_member" "default_sa_project_roles" {
  project = module.project_setup.project_id
  for_each = toset([ # Roles from original project-default-service-accounts
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/bigquery.user",
    "roles/storage.admin",
    "roles/pubsub.editor"
  ])
  role   = each.key
  member = "serviceAccount:${module.project_setup.default_service_account_email}"
}

resource "google_project_iam_member" "cloudbuild_sa_project_roles" {
  project = module.project_setup.project_id
  for_each = toset([ # Roles from original project-cloudbuild-service-accounts
    "roles/storage.admin",
    "roles/artifactregistry.createOnPushWriter",
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/cloudbuild.builds.editor"
  ])
  role   = each.key
  member = "serviceAccount:${module.project_setup.cloudbuild_service_account_email}"
}

# Module 2: Networking
module "networking" {
  source   = "./modules/networking"

  project_id        = module.project_setup.project_id
  resource_location = var.resource_location
  vpc_name          = "${var.project_id}-vpc" # From original main.tf
  subnet_name       = "us-subnet"             # From original main.tf
  subnet_ip_cidr_range = "10.0.1.0/24"        # From original main.tf
  subnet_description   = "Subnet us-central"  # From original main.tf
  
  # Firewall settings from original main.tf
  firewall_admin_ranges               = ["10.0.1.0/24"]
  firewall_ingress_source_ranges      = ["10.0.1.0/24"]
  firewall_ingress_sources_tags_or_sa = ["dataflow"]
  firewall_ingress_target_tags_or_sa  = ["dataflow"]
  # nat_name default is fine
}

# Module 3: Storage
module "storage" {
  source   = "./modules/storage"

  project_id               = module.project_setup.project_id
  location                 = var.resource_location # GCS location, e.g., "US" or a region
  bucket_prefix            = "daproject" # From original module "bucket"
  public_access_prevention = var.public_access_prevention
  enable_versioning        = false # From original module "bucket"
  bucket_labels = { # From original module "bucket"
    cost-center = "devops"
  }
}

# Module 4: Data Platform
module "data_platform" {
  source   = "./modules/data_platform"

  project_id                            = module.project_setup.project_id
  location                              = var.resource_location # For BQ dataset, e.g., "US"
  dataset_id                            = "demo_txn_dataset"    # From original main.tf
  table_name                            = "fake_txn"            # From original main.tf
  table_schema_path                     = "./table_schema.json" # Path relative to root
  topic_name                            = "fake-txn-topic"      # From original main.tf
  topic_schema_path                     = "./topic_schema.json" # Path relative to root
  pubsub_subscriber_service_account_email = module.project_setup.default_service_account_email
  delete_bq_contents_on_destroy       = true # From original main.tf
}

# Module 5: Stream Generator (Application)
module "stream_generator" {
  source   = "./modules/stream_generator"

  project_id                        = module.project_setup.project_id
  region                            = var.resource_location
  cloud_run_service_name            = "streamdata-generator" # From original main.tf
  container_image_name              = "streamdata-generator" # Used to construct GCR path
  cloud_build_sa_email              = module.project_setup.cloudbuild_service_account_email
  cloud_run_sa_email                = module.project_setup.default_service_account_email
  temp_bucket_url_for_build         = module.storage.bucket_url # gs://bucket-name
  pubsub_topic_name_for_generator   = module.data_platform.topic_name # Just the name
  
  # Paths to templates - these must exist at the root or specified path
  python_script_template_path     = "./streamdata-generator/main.tpl"
  cloudbuild_yaml_template_path   = "./streamdata-generator/cloudbuild.tpl"
  generator_source_code_directory = "./streamdata-generator" # Dir with Dockerfile etc.

  # Min/Max TPS from original main.tf's cloud_run module
  min_tps = 100
  max_tps = 2000
}
