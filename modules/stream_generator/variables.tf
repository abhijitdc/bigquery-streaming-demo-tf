variable "project_id" {
  type        = string
  description = "Project ID for Cloud Build, Cloud Run, and GCR."
}

variable "region" {
  type        = string
  description = "Region for the Cloud Run service."
}

variable "cloud_run_service_name" {
  type        = string
  default     = "streamdata-generator"
  description = "Name for the Cloud Run service and job."
}

variable "container_image_name" {
  type        = string
  default     = "streamdata-generator"
  description = "Name for the container image in GCR."
}

variable "cloud_build_sa_email" {
  type        = string
  description = "Service account email for Cloud Build."
}

variable "cloud_run_sa_email" {
  type        = string
  description = "Service account email for the Cloud Run service."
}

variable "temp_bucket_url_for_build" {
  type        = string
  description = "URL of the GCS bucket for Cloud Build temporary files (e.g., gs://bucket-name)."
}

variable "pubsub_topic_name_for_generator" {
  type        = string
  description = "Name of the Pub/Sub topic the generator will publish to (just the topic name, not the full path)."
}

variable "python_script_template_path" {
  type        = string
  description = "Path to the Python script template for the generator (e.g., './template.main.py.tpl'). Should be relative to the root module."
}

variable "cloudbuild_yaml_template_path" {
  type        = string
  description = "Path to the Cloud Build YAML template (e.g., './template.cloudbuild.yaml.tpl'). Should be relative to the root module."
}

variable "generator_source_code_directory" {
  type        = string
  description = "Directory containing the source code for the stream generator (Dockerfile, requirements.txt etc.). This path is used by Cloud Build."
}

variable "min_tps" {
  type        = number
  default     = 100
  description = "Min transactions per second for the stream generator."
}

variable "max_tps" {
  type        = number
  default     = 2000
  description = "Max transactions per second for the stream generator."
}
