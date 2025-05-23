output "cloud_run_job_name" {
  description = "Name of the created Cloud Run job."
  value       = module.cloud_run.job != null ? module.cloud_run.job.name : null
}

output "generated_container_image_url" {
  description = "The URL of the container image built and pushed to GCR."
  value       = local.gcr_image_url
}

# Outputs for service URL and name are less relevant if create_job = true
# but the CFF module might still populate them, or they could be conditional.
output "cloud_run_service_name" {
  description = "Name of the Cloud Run service (if one was created)."
  value       = module.cloud_run.service != null ? module.cloud_run.service.name : null
}

output "cloud_run_service_url" {
  description = "URL of the deployed Cloud Run service (if one was created)."
  value       = module.cloud_run.service != null ? module.cloud_run.service.url : null
}
