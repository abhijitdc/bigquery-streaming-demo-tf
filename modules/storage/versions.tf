terraform {
  required_providers {
    # This module uses the 'random' provider directly.
    random = {
      source = "hashicorp/random"
      # Version constraint for 'random' is managed by the root module's versions.tf
    }
    # It also uses the 'google' provider indirectly via the 'bucket' CFF module,
    # but the CFF module handles its own provider declaration.
    # Explicitly declaring 'google' here isn't strictly needed unless this module
    # were to use google provider resources directly. For clarity of direct use:
    # google = {
    #   source = "hashicorp/google"
    # }
  }
}
