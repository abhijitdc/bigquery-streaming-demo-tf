terraform {
  required_providers {
    # This module uses the 'local' and 'null' providers directly.
    local = {
      source = "hashicorp/local"
      # Version constraint for 'local' is managed by the root module.
    }
    null = {
      source = "hashicorp/null"
      # Version constraint for 'null' is managed by the root module.
    }
    # It also uses the 'google' provider indirectly via the 'cloud_run' CFF module,
    # but the CFF module handles its own provider declaration.
  }
}
