output "project_id" {
  description = "The created project ID."
  value       = module.project.project_id
}

output "project_number" {
  description = "The created project number."
  value       = module.project.number
}

output "default_service_account_email" {
  description = "Email of the default project service account."
  value       = module.project-default-service-accounts.email
}

output "cloudbuild_service_account_email" {
  description = "Email of the Cloud Build service account."
  value       = module.project-cloudbuild-service-accounts.email
}
