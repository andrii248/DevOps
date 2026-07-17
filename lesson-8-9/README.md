# CI/CD Pipeline with Jenkins, Kaniko, Amazon ECR, Argo CD and EKS

This project implements a complete CI/CD and GitOps workflow for a Django application deployed to Amazon EKS.

The infrastructure is managed with Terraform. Jenkins runs inside Kubernetes and uses Kaniko to build the application image without requiring Docker-in-Docker. The image is pushed to Amazon ECR, after which Jenkins updates the image tag in a separate GitOps repository. Argo CD detects the Git change and automatically deploys the new version to EKS.

## Architecture

```text
Developer
    |
    | git push
    v
GitHub DevOps repository
    |
    v
Jenkins on EKS
    |
    | Kaniko build
    v
Amazon ECR
    |
    | update image.tag
    v
GitHub GitOps repository
    |
    | automated synchronization
    v
Argo CD
    |
    v
Django application on Amazon EKS
```

## Repositories

### Application and infrastructure repository

Repository:

```text
https://github.com/andrii248/DevOps
```

Branch:

```text
lesson-8-9
```

The repository contains:

- Django application source code
- Dockerfile
- Jenkinsfile
- Terraform infrastructure
- Jenkins Terraform module
- Argo CD Terraform module
- EKS, ECR and VPC modules
- EBS CSI configuration
- Metrics Server configuration

### GitOps repository

Repository:

```text
https://github.com/andrii248/django-app-gitops
```

The GitOps repository contains the Helm chart used by Argo CD.

Jenkins automatically changes:

```yaml
image:
  repository: 732231074090.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr
  tag: "<jenkins-build-number>-<git-commit>"
```

Argo CD watches the `main` branch and deploys every new image tag.

## AWS Resources

| Resource                     | Value          |
| ---------------------------- | -------------- |
| AWS region                   | `us-west-2`    |
| EKS cluster                  | `lesson-7-eks` |
| ECR repository               | `lesson-7-ecr` |
| Jenkins namespace            | `jenkins`      |
| Argo CD namespace            | `argocd`       |
| Application namespace        | `django-app`   |
| Jenkins storage class        | `ebs-sc`       |
| Jenkins persistent volume    | `10Gi`         |
| Application minimum replicas | `2`            |
| Application maximum replicas | `6`            |
| HPA CPU target               | `70%`          |

## Infrastructure Components

### Amazon EKS

The application, Jenkins and Argo CD run inside the existing EKS cluster.

The worker nodes have permission to pull container images from Amazon ECR.

### Amazon ECR

Kaniko pushes versioned Django images to:

```text
732231074090.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr
```

An example generated image tag is:

```text
4-3ff4d8b
```

The tag consists of:

```text
Jenkins build number + short Git commit SHA
```

### Jenkins

Jenkins is installed through the official Helm chart and managed by Terraform.

Jenkins uses:

- Configuration as Code
- Job DSL
- Kubernetes agents
- Persistent EBS storage
- Kubernetes service account
- IAM Roles for Service Accounts
- GitHub credentials stored in a Kubernetes Secret

The pipeline job is created automatically:

```text
django-ci-cd
```

### Kaniko

Kaniko runs inside an ephemeral Kubernetes agent pod.

It builds the application using:

```text
Dockerfile: Dockerfile
Build context: repository root
```

Kaniko authenticates to ECR using the Jenkins Kubernetes service account and AWS IRSA. No static AWS access keys are stored in the repository.

### Argo CD

Argo CD is installed through Terraform and Helm.

The Argo CD Application watches:

```text
Repository: https://github.com/andrii248/django-app-gitops.git
Branch: main
Path: charts/django-app
```

Automated synchronization is enabled:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
```

This means that Argo CD:

- deploys new GitOps commits automatically;
- removes resources deleted from Git;
- restores resources changed manually in Kubernetes;
- creates the application namespace automatically.

### EBS CSI Driver

The Amazon EBS CSI Driver is installed as an EKS add-on.

It provides persistent EBS storage for Jenkins through the `ebs-sc` storage class.

### Metrics Server and HPA

Metrics Server provides CPU and memory metrics for Kubernetes.

The Django application uses a Horizontal Pod Autoscaler:

```text
Minimum replicas: 2
Maximum replicas: 6
Target CPU utilization: 70%
```

The HPA was verified successfully and reports live CPU utilization.

## Jenkins Pipeline

The `Jenkinsfile` contains three main stages.

### 1. Checkout

Jenkins checks out the `lesson-8-9` branch and creates an image tag from the build number and Git commit:

```text
BUILD_NUMBER-SHORT_COMMIT
```

Example:

```text
4-3ff4d8b
```

### 2. Build and Push Image

Kaniko builds the Django image and pushes it to Amazon ECR:

```text
732231074090.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:<IMAGE_TAG>
```

### 3. Update GitOps Repository

Jenkins clones the GitOps repository and updates:

```yaml
image.repository
image.tag
```

It then commits and pushes the change to the `main` branch.

Argo CD detects this commit and automatically deploys the new image.

## Application Helm Chart

The Helm chart contains:

- Deployment
- Service
- ServiceAccount
- ConfigMap
- HorizontalPodAutoscaler
- Startup probe
- Readiness probe
- Liveness probe
- CPU and memory requests
- CPU and memory limits

Application resources:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Deployment

### Terraform variables

The following environment variables are required:

```bash
export TF_VAR_app_repository_url="https://github.com/andrii248/DevOps.git"
export TF_VAR_github_owner="andrii248"

read -rsp "GitHub PAT: " TF_VAR_github_token
echo
export TF_VAR_github_token
```

The GitHub token is not committed to Git.

### Initialize and validate Terraform

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

### Apply infrastructure

```bash
terraform apply
```

### Start the Jenkins pipeline

Open Jenkins and run:

```text
django-ci-cd → Build Now
```

The successful pipeline:

1. checks out the source code;
2. builds the image with Kaniko;
3. pushes the image to ECR;
4. updates the GitOps repository;
5. triggers the Argo CD deployment.

## Verification

### Jenkins

```bash
kubectl get pods,pvc,svc -n jenkins
helm status jenkins -n jenkins
```

Expected result:

```text
jenkins-0   2/2   Running
PVC         Bound
Helm        deployed
```

### Argo CD

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
```

Expected result:

```text
django-app   Synced   Healthy
```

### Django application

```bash
kubectl get all -n django-app
```

Expected result:

- two running Django pods;
- one available deployment;
- LoadBalancer service;
- configured HPA.

### HPA and Metrics Server

```bash
kubectl top nodes
kubectl top pods -n django-app
kubectl get hpa -n django-app
```

Verified result:

```text
cpu: 6%/70%
MINPODS: 2
MAXPODS: 6
REPLICAS: 2
```

### Application endpoint

```bash
APP_HOST=$(kubectl -n django-app get svc django-app-chart \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -sS -o /dev/null \
  -w "HTTP status: %{http_code}\n" \
  "http://$APP_HOST"
```

Verified response:

```text
HTTP status: 200
```

### ECR image

```bash
aws ecr describe-images \
  --repository-name lesson-7-ecr \
  --region us-west-2 \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].{Tags:imageTags,Pushed:imagePushedAt,Digest:imageDigest}' \
  --output table
```

### Terraform state

```bash
terraform validate
terraform plan
```

Expected result:

```text
Success! The configuration is valid.
No changes. Your infrastructure matches the configuration.
```

## Security

The project avoids committing sensitive credentials.

Security measures include:

- GitHub PAT stored in a Kubernetes Secret;
- Jenkins credential masking;
- AWS permissions provided through IRSA;
- no AWS access keys stored in Jenkins or Git;
- ECR permissions limited to the Jenkins IAM role;
- application secrets separated from ConfigMap configuration;
- sensitive Terraform variables marked as sensitive.

The following values must never be committed:

- GitHub personal access tokens;
- AWS access keys;
- Jenkins passwords;
- Argo CD passwords;
- Terraform state files;
- saved Terraform plan files.

## Current Verified Status

The complete workflow has been tested successfully:

```text
GitHub
  → Jenkins
  → Kaniko
  → Amazon ECR
  → GitOps repository
  → Argo CD
  → Amazon EKS
  → Horizontal Pod Autoscaler
```

Verified state:

```text
Jenkins pipeline: SUCCESS
Argo CD sync: Synced
Argo CD health: Healthy
Django deployment: 2/2 available
Django pods: Running
Application HTTP response: 200
HPA metrics: Available
Terraform drift: No changes
```

## Limitations

This project is intended as a learning and demonstration environment.

For a production deployment, the following improvements would be recommended:

- HTTPS and TLS certificates;
- custom domain name;
- production WSGI server such as Gunicorn;
- managed PostgreSQL database;
- external secret management;
- network policies;
- monitoring and alerting;
- private load balancers where appropriate;
- Jenkins and Argo CD access restrictions.
