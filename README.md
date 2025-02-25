# BigQuery Real-Time Streaming Demo

This demo showcases real-time data streaming into BigQuery using Cloud Run, Pub/Sub, and Terraform. It simulates transactional data with `Faker`, streams it via Pub/Sub, and lands it directly into BigQuery using a Pub/Sub BigQuery subscription.

**Key Components:**

- **Cloud Run (Data Generator):** Simulates and publishes data.
- **Pub/Sub:** Message broker for decoupling.
- **BigQuery Subscription:** Streams data directly to BigQuery.
- **BigQuery Table:** Data storage for analysis.

**Data Flow:**

`Cloud Run --> Pub/Sub Topic --> BigQuery Subscription --> BigQuery Table`

**Core Features:**

- **Real-Time Streaming:** Near real-time data ingestion.
- **Scalable:** Cloud Run and Pub/Sub provide scalability.
- **Automated:** Terraform manages the entire infrastructure.
- **Realistic Data:** `Faker` library simulates real-world transactions.
- **BigQuery subscription:** Stream data directly to BigQuery table.

**Terraform:**

- Creates and configures all GCP resources (project, network, storage, Pub/Sub, BigQuery, Cloud Run, and cloud build).
- Manages IAM permissions.
- Manages Terraform state and provider versions.
- Creates `main.py` and `cloudbuild.yaml` from Jinja templates.

**`streamdata-generator` (Cloud Run Job):**

- Generates fake data using `Faker`.
- Publishes data to Pub/Sub.
- Containerized for easy deployment.
- Deployed using cloud build.

### streamdata-generator

The `streamdata-generator` is a crucial component of this demo, responsible for simulating real-time transactional data and publishing it to the Pub/Sub topic. It utilizes Python's `Faker` library to generate realistic fake data. This component is containerized and deployed to Cloud Run as a job, ensuring continuous data streaming.

**Key Functions:**

- **Data Generation:** Generates fake transactional data, including details like transaction ID, amount, timestamp, and other relevant fields, using the `Faker` library.
- **Pub/Sub Publishing:** Publishes the generated data to the designated Pub/Sub topic (`fake-txn-topic`).
- **Containerized Deployment:** Runs as a containerized job in Cloud Run, providing scalability and reliability.
- **Continuous Streaming:** Designed to continuously stream data, simulating a constant flow of real-time transactions.

**Files:**

- **`main.tpl` (Template):**
  - A Jinja template for the core Python script that handles data generation and Pub/Sub publishing.
  - Terraform uses this template to dynamically create the `main.py` file, injecting the correct Pub/Sub topic name and project ID.
- **`main.py` (Generated):**
  - The final Python script, created from `main.tpl` by Terraform, ready to be used in the container.
  - the file will contain the right `project_id` and `topic_name`.
- **`cloudbuild.tpl` (Template):**
  - A Jinja template for the Cloud Build configuration file (`cloudbuild.yaml`).
  - Terraform uses this template to dynamically create the `cloudbuild.yaml` file, injecting project ID, bucket name, service account for the build process.
- **`cloudbuild.yaml` (Generated):**
  - The final Cloud Build configuration file, created from `cloudbuild.tpl` by Terraform.
  - Defines the steps for building and pushing the Docker image to Artifact Registry, which will then be used by Cloud Run.
  - the file will contain the `project_id`, `service account email`, `bucket name`.
- **`requirements.txt`:** Lists the Python dependencies needed for the `streamdata-generator` script (e.g., `faker`, `google-cloud-pubsub`).

**Deployment:**

1. The `cloudbuild.yaml` file is used to create and push a docker image to Artifact Registry.
2. the docker image is used by cloud run to create a job.
3. The job is executed periodically to stream the data to the pub/sub topic.

**Terraform Role:**

Terraform is responsible for:

1. Creating `main.py` and `cloudbuild.yaml` from the jinja template files.
2. Creating a Cloud Run job to stream the data.
3. Create the required service account and permissions.
4. Create the required pub/sub topic.

> 💡 **Note:** Terraform currently configures the Cloud Build configuration file (`cloudbuild.yaml`) but does not automatically trigger the Cloud Build process. You'll need to manually trigger the build using `gcloud builds submit` or through the Cloud Build dashboard.

## Admin Project Configuration

The Admin Project centralizes Terraform state storage and simplifies Cloud SDK usage. It serves as the default GCP project in your Cloud SDK and hosts the Terraform state bucket.

**Why an Admin Project?**

- **Centralized State:** Securely stores Terraform state files for collaboration and consistency.
- **Simplified CLI:** Sets the default project for `gcloud` commands.
- **Project Creation:** Allows creating new projects in your organization.
- **Isolation:** Separates management tasks from demo project resources.
- **Security:** Isolates admin access from user access.

**Variables:**

- `admin_project_id` (string, **required**): The ID of the Admin Project (e.g., `"my-gcp-admin-project"`). _Must already exist_.
- `admin_project_region` (string, **required**): The region of the Admin Project (e.g., `"us-central1"`).
- `tfstate_bucket_name` (string, **required**): The name of the GCS bucket for Terraform state (e.g., `"dctoybox-tfstate"`). _Must already be created in the admin project_
- `admin_project_number` (number, **required**): The project number of the Admin Project (e.g., `789456123`).

**Setup:**

1.  **Create:** Create the Admin Project in GCP.
2.  **Configure Cloud SDK:** `gcloud config set project <admin_project_id>`
3.  **Bucket creation:** Make sure that the bucket define in `tfstate_bucket_name` is created in the admin project.
4.  **Permissions:** Ensure your Terraform user/service account has permissions to manage Cloud Storage in the Admin Project.

**Usage:**

Run Terraform commands from your local machine. Terraform will store its state in the Admin Project's bucket, and your `gcloud` commands will default to this project.

## Setup

This `main.tf` file orchestrates the creation of a Google Cloud Platform (GCP) project and its core components for demonstrating data streaming into BigQuery via Pub/Sub, leveraging the Google Cloud Foundation Fabric modules for automation and best practices. It also prepares a Cloud Run job and cloud build deployment.

**Key Responsibilities:**

- **Project Foundation:**
  - Creates a new GCP project using `var.project_id`.
  - Associates the project with a billing account (`var.billing_account_id`).
  - Places the project within a specified folder (`var.folder_id`).
  - Enables essential GCP services required for the demo (Pub/Sub, BigQuery, Compute, Storage, etc.).
- **Admin Project Configuration:**
  - The file also interact with the admin project defined in `variable.tf`.
  - create the storage for the state.
  - enable essential services.
- **IAM Permissions:**
  - Grants `pubsub.admin` and `bigquery.admin` roles to a specified user (`var.admin_user_email`).
  - Creates a default service account (`sa-default`) with necessary roles for BigQuery, Pub/Sub, and storage interactions.
  - Creates a service account for cloud build (`sabuild-default`) with necessary roles for Storage, Artifact Registry, IAM and cloud build actions.
- **Networking:**
  - Creates a VPC network (`{project_id}-vpc`) for the project.
  - Defines a subnet (`us-subnet`) with a private IP range and private google access enabled.
  - Sets up firewall rules to allow traffic from the subnet and from instances with tag `dataflow`.
  - Configures Cloud NAT to allow instances without external IP addresses to access the internet.
- **Storage:**
  - Creates a temporary Cloud Storage bucket (`tmp-bucket`) with enforced public access prevention.
- **BigQuery:**
  - Creates a BigQuery dataset (`demo_txn_dataset`).
  - Creates a partitioned table (`fake_txn`) within the dataset, using a schema from `user_schema.json`.
- **Pub/Sub:**
  - Creates a Pub/Sub topic (`fake-txn-topic`).
  - Defines the topic's message schema using AVRO format (from `topic_schema.json`).
  - Creates a subscription (`fake-txn-sub-bigquery`) to stream data from the topic into the `fake_txn` BigQuery table.
- **Cloud Run:**
  - Deploys a cloud run job (`streamdata-generator`) that will push data to the `fake-txn-topic`.
  - Configure image, environment variables, service account, region.
- **Cloud Build:**
  - Create the local file `main.py` from `main.tpl` and inject project and topic information.
  - Create the local file `cloudbuild.yaml` from `cloudbuild.tpl` and inject project, service account and bucket information.

**Dependencies & Configuration:**

- **`variables.tf`:** Defines reusable variables like `project_id`, `resource_location`, `billing_account_id`, `admin_user_email`, and more, allowing for easy customization.
- **Admin Variables:** Defines admin project and resources variable to work with.
- **`versions.tf`:**
  - Specifies the required Google provider version (`>= 6.15.0`).
  - Configures the Terraform state backend to use a Google Cloud Storage bucket (`dctoybox-tfstate`) for remote state storage.

**In Summary:**

The `main.tf` file automates the deployment of a complete GCP environment for a data streaming demonstration. It handles project setup, networking, security, data storage, Pub/Sub, and Cloud Run, promoting reusability and consistency through the use of variables, modules, and a state backend. It also handle the creation of local files for cloud run deployment.
