# Provider configuration is inherited from the root module

data "local_file" "table_schema" {
  filename = var.table_schema_path # Path to the BigQuery table schema JSON file, passed from the root module.
}

data "local_file" "topic_schema" {
  filename = var.topic_schema_path # Path to the Pub/Sub topic schema AVRO file, passed from the root module.
}

module "bigquery-dataset" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/bigquery-dataset?ref=v36.1.0"
  project_id = var.project_id
  id         = var.dataset_id    # The ID of the BigQuery dataset.
  location   = var.location      # The location of the BigQuery dataset.
  options = {
    default_partition_expiration_ms = null
    delete_contents_on_destroy      = var.delete_bq_contents_on_destroy
    max_time_travel_hours           = 168
  }
  tables = {
    # Defines the BigQuery table resource using the table name variable.
    "${var.table_name}" = {
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
  name       = var.topic_name # The name of the Pub/Sub topic.
  schema = {
    msg_encoding = "JSON"
    schema_type  = "AVRO"
    definition   = data.local_file.topic_schema.content
  }
  subscriptions = {
    # Defines a BigQuery subscription for the Pub/Sub topic.
    # The subscription name is dynamically constructed using the topic name.
    "${var.topic_name}-sub-bq" = { 
      bigquery = {
        table                 = module.bigquery-dataset.tables["${var.table_name}"].id
        use_topic_schema      = true
        write_metadata        = false
        drop_unknown_fields   = true
        service_account_email = var.pubsub_subscriber_service_account_email
      }
    }
  }
}
