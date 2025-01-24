# ADMIN project variables

variable "admin_project_id" {
  type    = string
  default = "dctoybox"
}
variable "admin_prefix" {
  type    = string
  default = "dctoybox"
}

variable "admin_resource_location" {
  type    = string
  default = "us-central1"
}

variable "admin_service_list" {
  type = list(string)
  default = ["serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "orgpolicy.googleapis.com",
    "iam.googleapis.com",
    "cloudasset.googleapis.com"
  ]
}

variable "admin_user_email" {
  type = string
}

# End of ADMIN project variables

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
