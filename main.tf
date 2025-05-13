

locals {

  iams = {
    pubsubAdmin = { role = "roles/pubsub.admin"
      member = "user:${var.tfrunner_user_email}"
    }
    bqAdmin = { role = "roles/bigquery.admin"
      member = "user:${var.tfrunner_user_email}"
    }
  }

  services = [
    "orgpolicy.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "iam.googleapis.com",
    "cloudasset.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "compute.googleapis.com",
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

module "project" {
  source                = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project?ref=v36.1.0"
  billing_account       = var.billing_account_id
  name                  = var.project_id
  parent                = var.folder_id
  services              = local.services
  iam_bindings_additive = local.iams
}

module "project-default-service-accounts" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "sa-default"
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/bigquery.jobUser",
      "roles/bigquery.dataEditor",
      "roles/bigquery.user",
      "roles/storage.admin",
      "roles/pubsub.editor"
    ]
  }
}


module "project-cloudbuild-service-accounts" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "sabuild-default"
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${module.project.project_id}" = [
      "roles/storage.admin",
      "roles/artifactregistry.createOnPushWriter",
      "roles/artifactregistry.reader",
      "roles/artifactregistry.writer",
      "roles/iam.serviceAccountUser",
      "roles/logging.logWriter",
      "roles/cloudbuild.builds.editor"
    ]
  }
}



module "my-vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc?ref=v36.1.0"
  project_id = var.project_id
  name       = "${var.project_id}-vpc"
  subnets = [
    # custom description and PGA disabled
    {
      name                  = "us-subnet"
      region                = var.resource_location
      ip_cidr_range         = "10.0.1.0/24",
      description           = "Subnet us-central"
      enable_private_access = true
    }
  ]
}

module "my-vpc-firewall" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc-firewall?ref=v36.1.0"
  project_id = var.project_id
  network    = module.my-vpc.name
  default_rules_config = {
    admin_ranges = ["10.0.1.0/24"]
  }

  ingress_rules = {

    allow-ingress-tag = {
      description   = "Allow ingress from a specific tag."
      source_ranges = ["10.0.1.0/24"]
      sources       = ["dataflow"]
      targets       = ["dataflow"]
    }
  }

}

module "nat" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-cloudnat?ref=v36.1.0"
  project_id     = module.project.project_id
  region         = module.my-vpc.subnets["us-central1/us-subnet"].region
  name           = "default"
  router_network = module.my-vpc.self_link
}

data "local_file" "table_schema" {
  filename = "./table_schema.json"
}

data "local_file" "topic_schema" {
  filename = "./topic_schema.json"
}


resource "random_string" "bucket_suffix" {
  length  = 6
  lower   = true
  upper   = false
  special = false
}

module "bucket" {
  source                   = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs?ref=v36.1.0"
  project_id               = var.project_id
  prefix                   = "daproject"
  name                     = "tmp-bucket-${random_string.bucket_suffix.result}"
  location                 = var.resource_location
  public_access_prevention = var.public_access_prevention
  versioning               = false
  labels = {
    cost-center = "devops"
  }
}


module "bigquery-dataset" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/bigquery-dataset?ref=v36.1.0"
  project_id = module.project.project_id
  id         = "demo_txn_dataset"
  location   = var.resource_location
  options = {
    # default_table_expiration_ms     = 3600000
    default_partition_expiration_ms = null
    delete_contents_on_destroy      = true
    max_time_travel_hours           = 168
  }
  tables = {
    fake_txn = {
      deletion_protection = false
      friendly_name       = "Fake Txn"
      schema              = data.local_file.table_schema.content
      partitioning = {
        time = { type = "DAY", expiration_ms = null }
      }
    }
  }
}

module "pubsub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/pubsub?ref=v36.1.0"
  project_id = var.project_id
  name       = "fake-txn-topic"
  # iam = {
  #   "roles/pubsub.editor" = ["serviceAccount:${module.project-default-service-accounts.email}"]
  # }
  schema = {
    msg_encoding = "JSON"
    schema_type  = "AVRO"
    definition   = (data.local_file.topic_schema.content)
  }
  subscriptions = {
    fake-txn-sub-bigquery = {
      bigquery = {
        table                 = "${module.bigquery-dataset.tables["fake_txn"].project}:${module.bigquery-dataset.tables["fake_txn"].dataset_id}.${module.bigquery-dataset.tables["fake_txn"].table_id}"
        use_topic_schema      = true
        write_metadata        = false
        drop_unknown_fields   = true
        service_account_email = module.project-default-service-accounts.email
      }
    }
  }
}

resource "local_file" "local_pyfile_to_deploy" {
  filename = "./streamdata-generator/main.py"
  content = templatefile("./streamdata-generator/main.tpl",
    {
      project_id = var.project_id
      topic_name = module.pubsub.topic.name
    }
  )
}

resource "local_file" "local_buildfile_to_deploy" {
  filename = "./streamdata-generator/cloudbuild.yaml"
  content = templatefile("./streamdata-generator/cloudbuild.tpl",
    {
      project_id = var.project_id
      build_sa   = module.project-cloudbuild-service-accounts.email
      tmp_bucket = module.bucket.url
    }
  )
}

resource "null_resource" "run_cloudbuild_script" {

  depends_on = [local_file.local_buildfile_to_deploy]

  triggers = {
    script_hash = "${sha256(local_file.local_pyfile_to_deploy.content)}"
  }

  # Use local-exec to run the script.
  provisioner "local-exec" {
    command = "gcloud builds submit --config ./streamdata-generator/cloudbuild.yaml ./streamdata-generator --project=${module.project.project_id}"
  }
}

module "cloud_run" {

  depends_on = [null_resource.run_cloudbuild_script]

  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/cloud-run-v2?ref=v36.1.0"
  project_id = module.project.project_id
  name       = "streamdata-generator"
  region     = var.resource_location
  create_job = true
  containers = {
    streamdata-generator = {
      image = "gcr.io/${module.project.project_id}/streamdata-generator"
      env = {
        GOOGLE_CLOUD_PROJECT = "${module.project.project_id}"
        PUBSUB_TOPIC         = "${module.pubsub.topic.name}"
        MIN_TPS              = 100
        MAX_TPS              = 2000
      }
    }
  }
  service_account_create = false
  service_account        = module.project-default-service-accounts.email
  # iam = {
  #   "roles/run.invoker" = ["serviceAccount:${module.project-default-service-accounts.email}"]
  # }
  deletion_protection = false
}

