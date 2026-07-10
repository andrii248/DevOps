# Lesson 7 - Kubernetes Deployment with Helm

## Project Overview

This project contains a Helm chart and application configuration for deploying a Django application to Kubernetes.

The deployment includes:

- a Docker image stored in Amazon ECR;
- a Helm chart for Kubernetes deployment;
- a Kubernetes Service for exposing the application inside the cluster;
- liveness, readiness, and startup probes for application health checks;
- updated Django settings for running the app successfully in Kubernetes.

## Project Structure

```text
lesson-7/
│
├── Dockerfile
├── chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── charts/
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── serviceaccount.yaml
│       ├── ingress.yaml
│       ├── hpa.yaml
│       ├── httproute.yaml
│       ├── _helpers.tpl
│       └── tests/
│           └── test-connection.yaml
│
├── app/
│   ├── manage.py
│   ├── requirements.txt
│   └── config/
│       ├── settings.py
│       ├── urls.py
│       ├── asgi.py
│       └── wsgi.py
│
└── README.md
```

## Deployment Description

### Dockerfile

The Dockerfile builds a Python 3.11 image for the Django application.

It copies the application source code, installs dependencies from `requirements.txt`, and starts Django with:

```bash
python manage.py runserver 0.0.0.0:8000
```

### Helm Chart

The Helm chart deploys the application into the `lesson-7` namespace.

It defines:

- a Deployment resource for the Django container;
- a Service resource exposing port 80 and forwarding traffic to container port 8000;
- health probes for Kubernetes application monitoring.

### Kubernetes Probes

The chart uses three types of probes:

- `startupProbe` — allows the application time to start before Kubernetes begins health enforcement;
- `readinessProbe` — checks when the application is ready to receive traffic;
- `livenessProbe` — checks whether the running application is still healthy.

These probes help prevent restart loops and ensure proper rollout behavior.

## Important Fixes

During the task, the following issues were fixed:

- container port mismatch between Django and Kubernetes;
- Service routing mismatch between port 80 and container port 8000;
- incorrect health probe configuration;
- image refresh issue caused by using the `latest` tag with cached images;
- Django database configuration pointing to PostgreSQL host `db`, which did not exist in Kubernetes.

To make the application start successfully, Django database settings were changed from PostgreSQL to SQLite.

## Application Configuration

In `app/config/settings.py`, the database configuration was updated to use SQLite:

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}
```

The `ALLOWED_HOSTS` setting was also updated for testing in Kubernetes:

```python
ALLOWED_HOSTS = ["*"]
```

## Helm Configuration

The main Helm values include:

- image repository in Amazon ECR;
- `containerPort: 8000`;
- `service.port: 80`;
- `service.targetPort: 8000`;
- `startupProbe`, `readinessProbe`, and `livenessProbe` settings;
- `image.pullPolicy: Always` to force pulling the latest updated image.

## Docker Commands

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

## Helm Commands

### Install or Upgrade Release

```bash
helm upgrade --install lesson-7 ./chart -n lesson-7
```

This command installs the Helm release if it does not exist, or upgrades it if it already exists.

### Check Rollout Status

```bash
kubectl rollout status deployment/lesson-7-chart -n lesson-7
```

This command verifies whether the Deployment was rolled out successfully.

### Check Pods

```bash
kubectl get pods -n lesson-7
```

This command shows the current pod status in the namespace.

### Describe Pod

```bash
kubectl describe pod -n lesson-7 <pod-name>
```

This command provides detailed pod information, including container state, probe status, and events.

### View Logs

```bash
kubectl logs -n lesson-7 <pod-name>
kubectl logs -n lesson-7 <pod-name> --previous
```

These commands are used for troubleshooting application startup and restart issues.

## Service Access

To access the application locally, port forwarding can be used:

```bash
kubectl port-forward -n lesson-7 service/lesson-7-chart 8080:80
```

After that, the application becomes available in the browser at:

```text
http://127.0.0.1:8080
```

## Final Result

After applying the fixes:

- the Helm deployment rolled out successfully;
- the new pod became `Ready`;
- the Kubernetes Service correctly forwarded traffic to the Django container;
- the application opened successfully in the browser.

## Notes

When using the `latest` image tag in Kubernetes, it is safer to set:

```yaml
image:
  pullPolicy: Always
```

This ensures that Kubernetes pulls the newest version of the image instead of reusing an older cached version.
