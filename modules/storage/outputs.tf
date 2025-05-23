output "bucket_name" {
  description = "The name of the GCS bucket."
  value       = module.bucket.name
}

output "bucket_url" {
  description = "The URL of the GCS bucket (gs://...)."
  value       = module.bucket.url
}
