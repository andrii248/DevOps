# Lesson 5 - Terraform AWS Infrastructure

## Project Overview

This project contains a Terraform configuration for basic AWS infrastructure deployment.

The infrastructure includes:

- remote Terraform state storage in Amazon S3;
- state locking with DynamoDB;
- a VPC with public and private subnets;
- an Amazon ECR repository for storing Docker images.

## Project Structure

```text
lesson-5/
│
├── main.tf
├── backend.tf
├── outputs.tf
├── README.md
│
├── modules/
│   ├── s3-backend/
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── ecr/
│       ├── ecr.tf
│       ├── variables.tf
│       └── outputs.tf
```

## Module Description

### s3-backend

The `s3-backend` module creates an S3 bucket for storing Terraform state files.

It also creates a DynamoDB table that is used for state locking to prevent concurrent Terraform operations.

### vpc

The `vpc` module creates the network infrastructure in AWS.

It includes:

- a VPC;
- 3 public subnets;
- 3 private subnets;
- an Internet Gateway;
- a NAT Gateway;
- route tables and route table associations.

### ecr

The `ecr` module creates an Amazon Elastic Container Registry repository.

It is used to store Docker images and supports image scanning on push.

## Terraform Commands

### Initialize Terraform

```bash
terraform init
```

This command initializes the Terraform working directory, downloads providers, and prepares the backend. [web:436]

### Preview Infrastructure Changes

```bash
terraform plan
```

This command shows what Terraform will create, update, or destroy before applying changes. [web:436][web:456]

### Apply Infrastructure Changes

```bash
terraform apply
```

This command creates or updates the infrastructure defined in the Terraform configuration. [web:454][web:436]

### Destroy Infrastructure

```bash
terraform destroy
```

This command removes all resources managed by the Terraform configuration. [web:452]

## Outputs

After successful deployment, Terraform can return outputs such as:

- S3 bucket URL;
- DynamoDB table name;
- ECR repository URL;
- VPC ID;
- public subnet IDs;
- private subnet IDs.

## Notes

Before running `terraform plan` or `terraform apply`, AWS credentials must be configured.

For local validation before the remote backend is fully available, the following commands can be used:

```bash
terraform init -backend=false
terraform validate
```
