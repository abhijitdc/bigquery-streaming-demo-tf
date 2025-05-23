output "project_id" {
  description = "The ID of the created Google Cloud project."
  value       = module.project_setup.project_id
}

output "project_number" {
  description = "The number of the created Google Cloud project."
  value       = module.project_setup.project_number
}

output "default_service_account_email" {
  description = "Email of the default service account for the project."
  value       = module.project_setup.default_service_account_email
}

output "cloudbuild_service_account_email" {
  description = "Email of the Cloud Build service account for the project."
  value       = module.project_setup.cloudbuild_service_account_email
}

output "vpc_name" {
  description = "Name of the VPC network created."
  value       = module.networking.vpc_name
}

output "main_storage_bucket_name" {
  description = "Name of the primary GCS bucket created."
  value       = module.storage.bucket_name
}

output "main_storage_bucket_url" {
  description = "URL of the primary GCS bucket created."
  value       = module.storage.bucket_url
}

output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset."
  value       = module.data_platform.dataset_id
}

output "bigquery_table_id" {
  description = "ID of the main BigQuery table (project:dataset.table)."
  value       = module.data_platform.table_id
}

output "pubsub_topic_id" {
  description = "Full ID of the main Pub/Sub topic."
  value       = module.data_platform.topic_id
}

output "stream_generator_cloud_run_job_name" {
  description = "Name of the Cloud Run job for the stream generator."
  value       = module.stream_generator.cloud_run_job_name
}

output "stream_generator_container_image_url" {
  description = "URL of the container image built for the stream generator."
  value       = module.stream_generator.generated_container_image_url
}
