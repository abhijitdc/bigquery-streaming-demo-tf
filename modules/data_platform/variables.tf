variable "project_id" {
  type        = string
  description = "Project ID for BigQuery and Pub/Sub resources."
}

variable "location" {
  type        = string
  description = "Location for BigQuery dataset and Pub/Sub resources, e.g., 'US'."
}

variable "dataset_id" {
  type        = string
  description = "ID for the BigQuery dataset."
  default     = "demo_txn_dataset"
}

variable "table_name" {
  type        = string
  description = "Name for the BigQuery table within the dataset."
  default     = "fake_txn"
}

variable "table_schema_path" {
  type        = string
  description = "Path to the JSON file defining the BigQuery table schema."
}

variable "topic_name" {
  type        = string
  description = "Name for the Pub/Sub topic."
  default     = "fake-txn-topic"
}

variable "topic_schema_path" {
  type        = string
  description = "Path to the JSON file defining the Pub/Sub topic schema."
}

variable "pubsub_subscriber_service_account_email" {
  type        = string
  description = "Service account email for the Pub/Sub BigQuery subscription."
}

variable "delete_bq_contents_on_destroy" {
  type        = bool
  default     = true
  description = "Whether to delete BigQuery dataset contents on destroy."
}
