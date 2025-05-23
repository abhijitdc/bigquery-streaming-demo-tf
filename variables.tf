variable "tfrunner_user_email" {
  type = string
}

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "resource_location" {
  description = "The Google Cloud region where resources will be deployed (e.g., 'us-central1')."
  type        = string
}

variable "public_access_prevention" {
  description = "Specifies whether to enforce public access prevention on GCS buckets. Default is 'enforced'."
  type        = string
  default     = "enforced"
}

variable "prefix" {
  description = "A prefix used to decorate the names of created resources for easier identification."
  type        = string
}

variable "billing_account_id" {
  description = "The ID of the Google Cloud Billing Account to associate with the project."
  type        = string
}

variable "folder_id" {
  description = "The ID of the Google Cloud Folder in which to create the project."
  type        = string
}
