# Lesson 7 - Kubernetes Deployment with Helm

## Project Overview

This project contains Terraform configuration and a Helm chart for deploying a Django application to an existing Amazon EKS cluster.

The deployment and infrastructure include:

- Amazon ECR repository for storing the Docker image;
- VPC, subnets, NAT gateway, and networking configured via Terraform modules;
- Amazon EKS cluster and node group managed with Terraform;
- a Helm chart for deploying the Django app into the lesson-7 namespace;
- a Kubernetes Service exposing the app inside the cluster on port 80 and forwarding to container port 8000;
- liveness, readiness, and startup probes for application health checks;
- updated Django settings for running the app successfully in Kubernetes.

## Project Structure

```text
lesson-7/
│
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── README.md
│
├── .terraform/
├── modules/
│   ├── ecr/
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   │   ├── eks.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── s3-backend/
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/
│       ├── vpc.tf
│       ├── routes.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── serviceaccount.yaml
            ├── configmap.yaml
            ├── ingress.yaml
            ├── hpa.yaml
            ├── httproute.yaml
            ├── _helpers.tpl
            └── tests/
                └── test-connection.yaml
```

## Terraform Infrastructure

### Root Configuration

The root Terraform files (`backend.tf`, `providers.tf`, `main.tf`, and `outputs.tf`) configure remote state, the AWS provider, and wiring for the child modules.

The configuration provisions or connects to:

- a VPC with public and private subnets and routing for EKS;
- an ECR repository for the Django image;
- an EKS cluster and managed node group for running pods;
- an S3 bucket and DynamoDB table for remote Terraform state and state locking.

`terraform validate` and `terraform plan` run successfully and currently show **no changes**, meaning the real AWS infrastructure matches the configuration.

### Terraform Commands

From the `lesson-7` directory:

```bash
terraform init
terraform validate
terraform plan
```

- `terraform init` initializes the backend and downloads providers and modules.
- `terraform validate` checks the configuration for syntax and internal consistency.
- `terraform plan` compares the current AWS infrastructure with the configuration and shows planned changes (currently “No changes”).

## Docker Image and ECR

The Django application image is built locally and pushed to Amazon ECR.

### Build Docker Image

```bash
docker build -t lesson-7-ecr:latest .
```

### Tag Docker Image for ECR

```bash
docker tag lesson-7-ecr:latest 732231074090.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:latest
```

### Push Docker Image to ECR

```bash
docker push 732231074090.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr:latest
```

The Helm chart references this image in `values.yaml` so that the Deployment pulls it when creating pods.

## Helm Chart

The `django-app` Helm chart deploys the Django container into the `lesson-7` namespace of the existing EKS cluster.

### Chart Contents

The chart defines:

- a Deployment for the Django application using the ECR image and container port 8000;
- a Service of type ClusterIP that exposes port 80 and forwards traffic to the pod’s HTTP port;
- a ServiceAccount for the pod;
- optional ConfigMap, Ingress, HTTPRoute, and HPA manifests;
- a `tests/test-connection.yaml` pod used by `helm test` to verify connectivity.

`helm lint` passes with no errors, confirming the chart is well-formed.

### Probes and Container Ports

The Deployment template configures:

- `containerPort: 8000` with the port name `http` for the Django process;
- `startupProbe` to give the app time to start before health checks begin;
- `readinessProbe` to indicate when the app is ready to serve traffic;
- `livenessProbe` to detect and restart unhealthy containers.

The Service listens on port 80 and uses `targetPort: http`, which maps to the container’s port 8000.

### Helm Values

Key values in `values.yaml` include:

- `image.repository: 732231074090.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr`;
- `image.tag: "latest"`;
- `image.pullPolicy: Always` to ensure the most recent image is fetched;
- `containerPort: 8000` for the Django app;
- `service.port: 80` and `service.targetPort: 8000` for HTTP routing;
- probe thresholds and timings for startup, readiness, and liveness.

### Helm Commands

From `lesson-7/charts/django-app`:

```bash
helm lint .
helm template django-app .
```

From the repository root (or `lesson-7`), using the chart path:

```bash
helm upgrade --install lesson-7 ./lesson-7/charts/django-app -n lesson-7
```

- `helm lint` validates chart structure and templates.
- `helm template` renders the full Kubernetes manifests for inspection.
- `helm upgrade --install` installs the release if it does not exist or upgrades it if it already exists.

After installation, tests can be run with:

```bash
helm test lesson-7 -n lesson-7
```

## Application Configuration

The Django configuration was adjusted to work reliably inside Kubernetes.

### Database Settings

Originally the app expected a PostgreSQL service named `db`, which did not exist in the EKS cluster. To avoid connection failures during startup, the database configuration was changed to use SQLite:

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}
```

This allows the container to start successfully without external database dependencies.

### Allowed Hosts

For testing in Kubernetes, the `ALLOWED_HOSTS` setting was relaxed:

```python
ALLOWED_HOSTS = ["*"]
```

This prevents Django from rejecting requests based on the Host header while services and ingress are being verified.

## Kubernetes Access and Debugging

### Check Resources

```bash
kubectl get pods -n lesson-7
kubectl get deployments -n lesson-7
kubectl get svc -n lesson-7
```

### Describe and Logs

```bash
kubectl describe pod -n lesson-7 <pod-name>
kubectl logs -n lesson-7 <pod-name>
kubectl logs -n lesson-7 <pod-name> --previous
```

These commands are used to inspect probe behavior, image versions, and container restarts.

### Port Forwarding

To access the application locally from a browser:

```bash
kubectl port-forward -n lesson-7 service/django-app-chart 8080:80
```

Then open:

```text
http://127.0.0.1:8080
```

The Service forwards HTTP traffic on port 80 to the Django container on port 8000.

## Final Result

With the corrected ports, probes, image settings, and Django configuration:

- Terraform reports no pending changes and the EKS infrastructure is in sync with the configuration;
- `helm lint` and `helm template` succeed for the `django-app` chart;
- the Helm deployment rolls out successfully and pods reach the Ready state;
- the Service routes traffic correctly to the Django container;
- the application can be opened in the browser via port forwarding.

## Notes

- When using the `latest` tag for images, combining it with `image.pullPolicy: Always` helps avoid stale cached images during deployments.
- For production environments, it is recommended to switch from SQLite back to PostgreSQL or another managed database service and to tighten `ALLOWED_HOSTS`.
