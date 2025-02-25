variable "tfrunner_user_email" {
  type = string
}

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "resource_location" {
  description = "GCP Region"
  type        = string
}

variable "public_access_prevention" {
  description = "GCS Public Access"
  type        = string
  default     = "enforced"
}

variable "prefix" {
  description = "Prefix to decorate resource names"
  type        = string
}

variable "billing_account_id" {
  description = "billing account id"
  type        = string
}

variable "folder_id" {
  description = "Folder id"
  type        = string
}
