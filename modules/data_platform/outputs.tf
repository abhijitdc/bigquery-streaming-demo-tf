output "dataset_id" {
  description = "The ID of the BigQuery dataset created."
  value       = module.bigquery-dataset.dataset_id
}

output "table_id" {
  description = "The ID of the BigQuery table created (format: project:dataset.table)."
  value       = module.bigquery-dataset.tables["${var.table_name}"].id
}

output "table_reference_id" {
  description = "The ID of the BigQuery table, typically in the format 'project:dataset.table'."
  value       = module.bigquery-dataset.tables["${var.table_name}"].id
}

output "topic_name" {
  description = "The name of the Pub/Sub topic created (e.g., 'fake-txn-topic')."
  value       = module.pubsub.topic.name
}

output "topic_id" {
  description = "The full ID of the Pub/Sub topic (format: projects/PROJECT_ID/topics/TOPIC_NAME)."
  value       = module.pubsub.topic.id
}
