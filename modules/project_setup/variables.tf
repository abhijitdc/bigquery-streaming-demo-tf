variable "tfrunner_user_email" {
  type        = string
  description = "Email of the user running Terraform, for IAM bindings."
}

variable "project_id_suffix" {
  type        = string
  description = "Suffix for the project ID. The actual project ID will be composed based on other factors if needed, or this can be the full ID if desired."
  # Example: if you want project_id to be "my-gcp-project", this could be "my-gcp-project"
  # Or if you have a standard prefix, this could be "suffix" and prefix is handled in module main.tf
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID for the project."
}

variable "folder_id" {
  type        = string
  description = "Folder ID where the project will be created."
}

variable "custom_services" {
  type        = list(string)
  default     = []
  description = "A list of additional services to enable on the project."
}

variable "enable_oslogin" {
  type        = bool
  default     = false # Defaulting to false to match original behavior unless overridden
  description = "Whether to enforce OS Login on the project. True for enforced, false for not enforced."
}
