# Provider configuration is inherited from the root module

# The local_file resources in this module generate the Python script and Cloud Build YAML configuration
# that will be used by Cloud Build to create the container image for the stream generator.
# Cloud Build typically works relative to the source directory specified in the `gcloud builds submit` command.

locals {
  # Constructs the Google Container Registry (GCR) URL for the image.
  gcr_image_url = "gcr.io/${var.project_id}/${var.container_image_name}"

  # These local_file resources generate files on the machine where Terraform is executed.
  # The Cloud Build command (`gcloud builds submit`) must be able to access these generated files
  # (e.g., by running Terraform from a directory that is part of the build context, or by copying them).
  generated_python_script_path = "${var.generator_source_code_directory}/main.py"     # Path on the machine running Terraform for the generated Python script.
  generated_cloudbuild_yaml_path = "./cloudbuild_generated.yaml" # Path on the machine running Terraform for the generated Cloud Build YAML.
}

resource "local_file" "local_pyfile_to_deploy" {
  filename = local.generated_python_script_path 
  content = templatefile(var.python_script_template_path, {
    project_id = var.project_id
    topic_name = var.pubsub_topic_name_for_generator # The name of the Pub/Sub topic.
  })
}

resource "local_file" "local_buildfile_to_deploy" {
  filename = local.generated_cloudbuild_yaml_path
  content = templatefile(var.cloudbuild_yaml_template_path, {
    project_id = var.project_id
    build_sa   = var.cloud_build_sa_email
    tmp_bucket = var.temp_bucket_url_for_build # GCS bucket URL (gs://bucket-name) for build artifacts.
    gcr_image_path = local.gcr_image_url     # Fully constructed GCR image path for the build.
  })
}

# Triggers a Cloud Build pipeline to build and push the data generator container image.
resource "null_resource" "run_cloudbuild_script" {
  # Ensures that the Cloud Build process runs only after the necessary configuration files are generated.
  depends_on = [
    local_file.local_pyfile_to_deploy,
    local_file.local_buildfile_to_deploy
  ]

  triggers = {
    # The build will re-run if the content of the generated Python script (application logic)
    # or the generated Cloud Build configuration changes.
    # Changes to the source templates will also trigger a new build.
    script_hash      = sha256(local_file.local_pyfile_to_deploy.content)
    build_config_hash = sha256(local_file.local_buildfile_to_deploy.content)
  }

  # Executes the gcloud command to submit the build.
  # The command requires access to the generated Cloud Build YAML and the source code directory.
  provisioner "local-exec" {
    # The `var.generator_source_code_directory` provides the build context (e.g., location of Dockerfile).
    # The generated cloudbuild.yaml should correctly reference main_generated.py (e.g., by copying it into the build context).
    command = "gcloud builds submit --config ${local.generated_cloudbuild_yaml_path} ${var.generator_source_code_directory} --project=${var.project_id}"
  }
}

# Deploys the data generator as a Cloud Run v2 job.
module "cloud_run" {
  depends_on = [null_resource.run_cloudbuild_script] # Ensures the Cloud Run job is created only after the image build is complete.

  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/cloud-run-v2?ref=v36.1.0"
  project_id = var.project_id
  name       = var.cloud_run_service_name # Name of the Cloud Run job.
  region     = var.region
  create_job = true # Specifies that a Cloud Run job (rather than a service) should be created.
  
  containers = {
    # Defines the container for the Cloud Run job. The key is the container's name within the job specification.
    "${var.container_image_name}" = { # Uses the image name as the key for the container definition.
      image = local.gcr_image_url    # Specifies the GCR image built by Cloud Build.
      env = {
        "GOOGLE_CLOUD_PROJECT" = var.project_id,
        "PUBSUB_TOPIC"         = var.pubsub_topic_name_for_generator, # Name of the Pub/Sub topic used by the generator.
        "MIN_TPS"              = tostring(var.min_tps),
        "MAX_TPS"              = tostring(var.max_tps)
      }
    }
  }
  service_account        = var.cloud_run_sa_email
  service_account_create = false # Uses an existing service account.
  deletion_protection    = false
}
