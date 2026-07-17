variable "namespace" {
  description = "Namespace where Argo CD is installed"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "10.1.4"
}

variable "gitops_repository_url" {
  description = "GitOps repository watched by Argo CD"
  type        = string
}

variable "gitops_revision" {
  description = "GitOps repository branch"
  type        = string
  default     = "main"
}

variable "gitops_chart_path" {
  description = "Path to the application Helm chart"
  type        = string
  default     = "charts/django-app"
}

variable "application_name" {
  description = "Argo CD application name"
  type        = string
  default     = "django-app"
}

variable "application_namespace" {
  description = "Namespace where Django is deployed"
  type        = string
  default     = "django-app"
}
