# Provision a GCP project using Terraform to run a cmpute VM and a BigQuery table

## Introduction

This Terraform configuration automates the following

- Provisioning of a GCP project,
- Setup VPC, firewall rules and provision a NAT
- Creating a BigQuery dataset and a table
- Launch a private VM to access via IAP

## Prerequisites

- A Google Cloud Platform (GCP) account.
- The `gcloud` command-line tool installed and configured.
- Terraform installed on your local machine.
- Configure application default login credential
