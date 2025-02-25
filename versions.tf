
terraform {
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
    bucket = "dctoybox-tfstate"                # Use your existing bucket
    prefix = "terraform/bqstreamproject/state" # Example prefix
  }
}
