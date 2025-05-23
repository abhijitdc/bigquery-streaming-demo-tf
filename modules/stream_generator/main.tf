# Provider configuration is inherited from the root module

# Path for the generated files within the module's execution context (if needed temporarily)
# However, Cloud Build usually works relative to the source directory specified in the gcloud command.
# The local_file resources here are more about generating the config that Cloud Build will use.

locals {
  # Construct the GCR image URL
  gcr_image_url = "gcr.io/${var.project_id}/${var.container_image_name}"

  # Define where the generated files will be placed for Cloud Build to pick up.
  # These paths should be relative to the `var.generator_source_code_directory`
  # or Cloud Build should be configured to find them.
  # For simplicity, we'll assume these generated files are placed directly in the
  # root of the `var.generator_source_code_directory` before Cloud Build runs.
  # This might require the `local_file` destination to be dynamic based on that variable.
  # However, `local_file` writes to the terraform host, not necessarily into the build context directly.
  # A common pattern is to output the content and have the null_resource script use it,
  # or ensure `gcloud builds submit` is run from a location where these files are accessible.

  # For this refactoring, we'll keep the local_file resources generating files in a known path
  # relative to where terraform is executed, and assume the cloud build command can access them.
  # This matches the original structure.
  generated_python_script_path = "./main_generated.py" # Path on the machine running Terraform
  generated_cloudbuild_yaml_path = "./cloudbuild_generated.yaml" # Path on the machine running Terraform
}

resource "local_file" "local_pyfile_to_deploy" {
  filename = local.generated_python_script_path 
  content = templatefile(var.python_script_template_path, {
    project_id = var.project_id
    topic_name = var.pubsub_topic_name_for_generator # Just the name, as per original tpl
  })
}

resource "local_file" "local_buildfile_to_deploy" {
  filename = local.generated_cloudbuild_yaml_path
  content = templatefile(var.cloudbuild_yaml_template_path, {
    project_id = var.project_id
    build_sa   = var.cloud_build_sa_email
    tmp_bucket = var.temp_bucket_url_for_build # Should be gs://bucket-name
    # Ensure the template expects 'gcr_image_url' or constructs it similarly
    gcr_image_path = local.gcr_image_url # Pass the fully constructed image path
  })
}

# Triggers a Cloud Build pipeline to build and push the data generator container image.
resource "null_resource" "run_cloudbuild_script" {
  # This depends on the generated files being ready.
  depends_on = [
    local_file.local_pyfile_to_deploy,
    local_file.local_buildfile_to_deploy
  ]

  triggers = {
    # Re-run build if the content of the generated python script (app logic) changes
    # or if the build configuration itself changes.
    # Note: If the *templates* change, these local_file resources will re-trigger,
    # then this null_resource will re-trigger.
    script_hash      = sha256(local_file.local_pyfile_to_deploy.content)
    build_config_hash = sha256(local_file.local_buildfile_to_deploy.content)
    # Add other triggers if necessary, e.g., Dockerfile content if not captured by above.
  }

  # Use local-exec to run the script.
  # The paths to config and source dir are crucial.
  provisioner "local-exec" {
    # Assumes cloudbuild_generated.yaml and main_generated.py are in the CWD where terraform runs,
    # or accessible at the paths specified.
    # `var.generator_source_code_directory` is the context for the build (e.g., where Dockerfile is)
    # The generated cloudbuild.yaml needs to correctly reference main_generated.py (e.g. copy it into build context)
    command = "gcloud builds submit --config ${local.generated_cloudbuild_yaml_path} ${var.generator_source_code_directory} --project=${var.project_id}"
  }
}

# Deploys the data generator as a Cloud Run v2 job.
module "cloud_run" {
  depends_on = [null_resource.run_cloudbuild_script] # Ensure build is complete

  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/cloud-run-v2?ref=v36.1.0"
  project_id = var.project_id
  name       = var.cloud_run_service_name # This will be the job name
  region     = var.region
  create_job = true # Explicitly creating a job as per original main.tf
  
  containers = {
    # The key for this map is the container name within the job spec
    "${var.container_image_name}" = { # Use the image name for the container key
      image = local.gcr_image_url    # Use the image built by Cloud Build
      env = [
        { name = "GOOGLE_CLOUD_PROJECT", value = var.project_id },
        { name = "PUBSUB_TOPIC", value = var.pubsub_topic_name_for_generator }, # Just the name
        { name = "MIN_TPS", value = var.min_tps },
        { name = "MAX_TPS", value = var.max_tps }
      ]
      # Add other container settings like resources, ports if it were a service
    }
  }
  service_account        = var.cloud_run_sa_email
  service_account_create = false # We are providing an existing SA
  deletion_protection    = false # Or make configurable
}
