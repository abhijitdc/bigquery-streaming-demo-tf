output "dataset_id" {
  description = "The ID of the BigQuery dataset created."
  value       = module.bigquery-dataset.dataset_id # Corrected to fabric output
}

output "table_id" {
  description = "The ID of the BigQuery table created (format: project:dataset.table)."
  value       = module.bigquery-dataset.tables["${var.table_name}"].id # Corrected to fabric output
}

output "table_reference_id" {
  description = "The reference ID of the BigQuery table (format: projects/PROJECT_ID/datasets/DATASET_ID/tables/TABLE_ID)."
  # The CFF module for BQ dataset usually outputs the table resource itself, which has an 'id' like 'projects/p/datasets/d/tables/t'
  # or a specific 'table_id' attribute.
  # module.bigquery-dataset.tables["${var.table_name}"].id is usually project:dataset.table
  # For the full resource id, you might need to construct it or check fabric module's exact output.
  # Let's assume module.bigquery-dataset.tables_data["${var.table_name}"].id gives the full path if available,
  # or we stick to the one above. The CFF bigquery-dataset module's 'tables' output value is a map of the table resources.
  # The 'id' attribute of a google_bigquery_table is 'projects/{{project}}/datasets/{{dataset_id}}/tables/{{table_id}}'.
  # The module's output `module.bigquery-dataset.tables["fake_txn"].id` provides `project_id:dataset_id.table_id`
  # The `google_bigquery_table` resource itself has an `id` attribute that is the full path.
  # The CFF module's `tables` output is a map of `google_bigquery_table` objects.
  value = module.bigquery-dataset.tables["${var.table_name}"].id # This is likely project:dataset.table
  # To get the full path, it might be module.bigquery-dataset.tables_data["${var.table_name}"].id if the module exposes the full object
  # For now, this is the most direct reference from the module's output structure.
}

output "topic_name" {
  description = "The name of the Pub/Sub topic created (just the name, not full path)."
  value       = module.pubsub.topic.name
}

output "topic_id" {
  description = "The full ID of the Pub/Sub topic (format: projects/PROJECT_ID/topics/TOPIC_NAME)."
  value       = module.pubsub.topic.id # This is the correct CFF module output for the full topic ID
}
