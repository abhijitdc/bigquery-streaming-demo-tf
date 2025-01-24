# BigQuery Streaming Demo with Cloud Run, Pub/Sub and Terraform automation

This demo showcases real-time data streaming into BigQuery using Cloud Run, Pub/Sub, and a BigQuery subscription. It simulates transactional data, streams it through Pub/Sub, and then queries the resulting BigQuery table. This demonstrates a common and scalable architecture for real-time analytics.

## Architecture Overview

The data flows as follows:

Cloud Run (Data Generation) --> Pub/Sub Topic --> BigQuery Subscription --> BigQuery Table

## Key Components and Technologies

- **Cloud Run:** Serverless compute platform for running the data generation script. Its scalability and on-demand nature make it ideal for this task.
- **Pub/Sub:** Messaging service providing reliable and asynchronous data ingestion into BigQuery. This decouples the data generator from BigQuery.
- **BigQuery:** Data warehouse for storing and analyzing the streamed data. BigQuery's ability to handle large data volumes and complex queries makes it a powerful analytics platform.
- **Faker:** Python library used to generate realistic fake transaction data.
- **BigQuery Subscription:** Links Pub/Sub and BigQuery, enabling automatic data streaming.
- **Terraform:** Infrastructure-as-code tool used to define and manage the Google Cloud resources. This ensures consistent and repeatable deployments. Terraform also dynamically modifies the Python script and Cloud Build configuration file, injecting values like the GCP Project ID and Pub/Sub topic name, streamlining the deployment process.
