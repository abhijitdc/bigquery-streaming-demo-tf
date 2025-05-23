
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      version = ">= 6.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  backend "gcs" {
    bucket = "dctoybox-tfstate"                # GCS bucket for storing Terraform state.
    prefix = "terraform/bqstreamproject/state" # Prefix within the GCS bucket for this project's state.
  }
}
