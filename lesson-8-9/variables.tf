variable "app_repository_url" {
  description = "GitHub repository containing the Django application and Jenkinsfile"
  type        = string
}

variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token used by Jenkins"
  type        = string
  sensitive   = true
}
