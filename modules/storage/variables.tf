variable "project_id" {
  type        = string
  description = "The ID of the project where the GCS bucket will be created."
}

variable "location" {
  type        = string
  description = "The location for the GCS bucket, e.g., 'US' or 'us-central1'."
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix for the GCS bucket name."
  default     = "daproject-tmp" # Matches current use, but more generic
}

variable "public_access_prevention" {
  type        = string
  default     = "enforced"
  description = "Public access prevention policy for the GCS bucket. Options: 'enforced', 'inherited'."
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "Enable versioning for the GCS bucket."
}

variable "bucket_labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to the GCS bucket."
}
