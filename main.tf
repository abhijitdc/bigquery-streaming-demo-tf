provider "google" {
  user_project_override = true
  # The billing_project is used if the user running Terraform does not have project ownership.
  billing_project       = "dctoybox"
}

# Variables for this root module are defined in variables.tf.

# Module 1: Project Setup (Foundation)
# This module handles the initial project creation and configuration, including service enablement.
module "project_setup" {
  source   = "./modules/project_setup"

  tfrunner_user_email = var.tfrunner_user_email
  project_id_suffix   = var.project_id # Suffix for the generated project ID.
  billing_account_id  = var.billing_account_id
  folder_id           = var.folder_id
  enable_oslogin      = false # Disables OS Login for Compute Engine instances.
  
  # Specifies additional Google Cloud services to enable beyond those configured by default in the project_setup module.
  # These services are required for various components of the data platform and application.
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

# IAM bindings for the service accounts created in the project_setup module.
# These bindings grant necessary permissions at the project level.

resource "google_project_iam_member" "default_sa_project_roles" {
  project = module.project_setup.project_id
  for_each = toset([ # Defines roles for the default service account.
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
  for_each = toset([ # Defines roles for the Cloud Build service account.
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
# This module sets up the Virtual Private Cloud (VPC), subnets, firewall rules, and NAT gateway.
module "networking" {
  source   = "./modules/networking"

  project_id        = module.project_setup.project_id
  resource_location = var.resource_location
  vpc_name          = "${var.project_id}-vpc"
  subnet_name       = "us-subnet"
  subnet_ip_cidr_range = "10.0.1.0/24"
  subnet_description   = "Subnet us-central"
  
  # Firewall configuration.
  firewall_admin_ranges               = ["10.0.1.0/24"]
  firewall_ingress_source_ranges      = ["10.0.1.0/24"]
  firewall_ingress_sources_tags_or_sa = ["dataflow"]
  firewall_ingress_target_tags_or_sa  = ["dataflow"]
}

# Module 3: Storage
# This module provisions Google Cloud Storage buckets.
module "storage" {
  source   = "./modules/storage"

  project_id               = module.project_setup.project_id
  location                 = var.resource_location # Specifies the GCS location (e.g., "US", "EU", or a specific region).
  bucket_prefix            = "daproject"
  public_access_prevention = var.public_access_prevention
  enable_versioning        = false
  bucket_labels = {
    cost-center = "devops"
  }
}

# Module 4: Data Platform
# This module configures BigQuery datasets, tables, and Pub/Sub topics for the data platform.
module "data_platform" {
  source   = "./modules/data_platform"

  project_id                            = module.project_setup.project_id
  location                              = var.resource_location # Specifies the location for the BigQuery dataset (e.g., "US").
  dataset_id                            = "demo_txn_dataset"
  table_name                            = "fake_txn"
  table_schema_path                     = "./table_schema.json" # Path to the table schema, relative to the root module.
  topic_name                            = "fake-txn-topic"
  topic_schema_path                     = "./topic_schema.json" # Path to the topic schema, relative to the root module.
  pubsub_subscriber_service_account_email = module.project_setup.default_service_account_email
  delete_bq_contents_on_destroy       = true
}

# Module 5: Stream Generator (Application)
# This module deploys the stream data generator application using Cloud Build and Cloud Run.
module "stream_generator" {
  source   = "./modules/stream_generator"

  project_id                        = module.project_setup.project_id
  region                            = var.resource_location
  cloud_run_service_name            = "streamdata-generator"
  container_image_name              = "streamdata-generator" # Name used to construct the Google Container Registry path for the image.
  cloud_build_sa_email              = module.project_setup.cloudbuild_service_account_email
  cloud_run_sa_email                = module.project_setup.default_service_account_email
  temp_bucket_url_for_build         = module.storage.bucket_url # GCS bucket URL for Cloud Build artifacts (e.g., gs://bucket-name).
  pubsub_topic_name_for_generator   = module.data_platform.topic_name # Name of the Pub/Sub topic for the generator.
  
  # Paths to the template files used by Cloud Build; these must exist at the specified location.
  python_script_template_path     = "./streamdata-generator/main.tpl"
  cloudbuild_yaml_template_path   = "./streamdata-generator/cloudbuild.tpl"
  generator_source_code_directory = "./streamdata-generator" # Directory containing the Dockerfile and source code for the generator.

  # Configuration for the stream generator's transactions per second (TPS).
  min_tps = 100
  max_tps = 2000
}
