variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "app_repository_url" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "namespace" {
  type    = string
  default = "jenkins"
}

variable "chart_version" {
  type    = string
  default = "5.9.34"
}
