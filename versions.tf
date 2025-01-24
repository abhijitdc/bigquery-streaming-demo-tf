
terraform {
  required_providers {
    google = {
      version = ">= 6.15.0"
    }
  }
  backend "gcs" {
    bucket = "dctoybox-tfstate"          # Use your existing bucket
    prefix = "terraform/daproject/state" # Example prefix
  }
}
