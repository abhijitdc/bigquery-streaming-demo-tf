# Provider configuration is inherited from the root module

data "local_file" "table_schema" {
  filename = var.table_schema_path # Path passed from root module
}

data "local_file" "topic_schema" {
  filename = var.topic_schema_path # Path passed from root module
}

module "bigquery-dataset" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/bigquery-dataset?ref=v36.1.0"
  project_id = var.project_id
  id         = var.dataset_id    # e.g., "demo_txn_dataset"
  location   = var.location      # e.g., "US"
  options = {
    default_partition_expiration_ms = null # Or make configurable
    delete_contents_on_destroy      = var.delete_bq_contents_on_destroy
    max_time_travel_hours           = 168 # Or make configurable
  }
  tables = {
    # Using var.table_name to define the table key and its properties
    "${var.table_name}" = {
      deletion_protection = false # Or make configurable
      friendly_name       = "Fake Txn" # Consider making this a variable e.g., var.table_friendly_name
      schema              = data.local_file.table_schema.content
      partitioning = {
        time = { type = "DAY", expiration_ms = null } # Or make configurable
      }
    }
  }
}

module "pubsub" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/pubsub?ref=v36.1.0"
  project_id = var.project_id
  name       = var.topic_name # e.g., "fake-txn-topic"
  schema = {
    msg_encoding = "JSON" # Or make configurable
    schema_type  = "AVRO" # Or make configurable
    definition   = data.local_file.topic_schema.content
  }
  subscriptions = {
    # Construct subscription name, e.g., "fake-txn-topic-sub-bigquery"
    "${var.topic_name}-sub-bq" = { 
      bigquery = {
        table                 = module.bigquery-dataset.tables["${var.table_name}"].id # Correctly reference BQ table ID
        use_topic_schema      = true
        write_metadata        = false # Or make configurable
        drop_unknown_fields   = true  # Or make configurable
        service_account_email = var.pubsub_subscriber_service_account_email
      }
    }
  }
}
