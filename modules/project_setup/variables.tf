variable "tfrunner_user_email" {
  type        = string
  description = "Email of the user running Terraform, for IAM bindings."
}

variable "project_id_suffix" {
  type        = string
  description = "The desired name or suffix for the Google Cloud project ID."
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
  default     = false
  description = "Whether to enforce OS Login on the project. Set to true to enforce OS Login, false otherwise."
}
