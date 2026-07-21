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

variable "use_aurora" {
  description = "Creates Aurora when true or one standard RDS instance when false."
  type        = bool
  default     = false
}

variable "db_engine" {
  description = "Standard RDS engine: postgres or mysql."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Standard RDS engine version and the fallback Aurora version."
  type        = string
  default     = "16.4"
}

variable "db_engine_cluster" {
  description = "Optional Aurora engine override: aurora-postgresql or aurora-mysql. Null derives it from db_engine."
  type        = string
  default     = null
  nullable    = true
}

variable "db_engine_version_cluster" {
  description = "Optional Aurora version override. Null reuses db_engine_version."
  type        = string
  default     = null
  nullable    = true
}

variable "db_parameter_group_family_rds" {
  description = "Optional standard RDS parameter-group family. Null enables automatic derivation."
  type        = string
  default     = null
  nullable    = true
}

variable "db_parameter_group_family_aurora" {
  description = "Optional Aurora cluster parameter-group family. Null enables automatic derivation."
  type        = string
  default     = null
  nullable    = true
}

variable "db_instance_class" {
  description = "Instance class for standard RDS and Aurora instances."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_aurora_replica_count" {
  description = "Optional Aurora reader count in addition to the required writer."
  type        = number
  default     = 0
}

variable "db_multi_az" {
  description = "Enables Multi-AZ for standard RDS. Ignored for Aurora."
  type        = bool
  default     = false
}

variable "db_publicly_accessible" {
  description = "Uses public subnets and public DB endpoints when true. Keep false for the normal private deployment."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "django"
}

variable "db_username" {
  description = "Master database username."
  type        = string
  default     = "dbadmin"
}

variable "db_manage_master_user_password" {
  description = "Lets AWS Secrets Manager generate and manage the master password."
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Master password used only when db_manage_master_user_password is false."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}
