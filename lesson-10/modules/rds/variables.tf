variable "name" {
  description = "Name prefix used for all RDS resources. Use lowercase letters, numbers, and hyphens."
  type        = string
  default     = "application-db"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "The name must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "use_aurora" {
  description = "When true, creates an Aurora cluster with one writer and optional readers. When false, creates one standard RDS DB instance."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where the database security group is created."
  type        = string
}

variable "subnet_private_ids" {
  description = "Private subnet IDs used by the DB subnet group when publicly_accessible is false."
  type        = list(string)

  validation {
    condition     = length(var.subnet_private_ids) >= 2
    error_message = "At least two private subnet IDs are required for an RDS DB subnet group."
  }
}

variable "subnet_public_ids" {
  description = "Public subnet IDs used by the DB subnet group when publicly_accessible is true."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database port. Keep this restricted to trusted networks."
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Engine for a standard RDS instance. Supported values: postgres or mysql."
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], lower(var.engine))
    error_message = "Supported standard RDS engines are postgres and mysql."
  }
}

variable "engine_version" {
  description = "Engine version for a standard RDS instance. It is also used by Aurora when engine_version_cluster is null."
  type        = string
  default     = "16.4"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+", var.engine_version))
    error_message = "engine_version must begin with a numeric major and minor version, for example 16.4 or 8.0.40."
  }
}

variable "engine_cluster" {
  description = "Optional Aurora engine override: aurora-postgresql or aurora-mysql. When null, it is derived from engine."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.engine_cluster == null || contains([
      "aurora-postgresql",
      "aurora-mysql"
    ], lower(var.engine_cluster))
    error_message = "engine_cluster must be aurora-postgresql, aurora-mysql, or null."
  }
}

variable "engine_version_cluster" {
  description = "Optional Aurora engine version. When null, engine_version is used, keeping the RDS/Aurora switch minimal."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.engine_version_cluster == null || can(regex("^[0-9]+\\.[0-9]+", var.engine_version_cluster))
    error_message = "engine_version_cluster must be null or begin with a numeric major and minor version."
  }
}

variable "parameter_group_family_rds" {
  description = "Optional standard RDS parameter-group family, for example postgres16 or mysql8.0. When null, it is derived automatically."
  type        = string
  default     = null
  nullable    = true
}

variable "parameter_group_family_aurora" {
  description = "Optional Aurora cluster parameter-group family, for example aurora-postgresql16 or aurora-mysql8.0. When null, it is derived automatically."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_class" {
  description = "DB instance class used by the standard RDS instance and all Aurora instances."
  type        = string
  default     = "db.t4g.medium"
}

variable "aurora_replica_count" {
  description = "Number of optional Aurora read replicas in addition to the required writer. Ignored for standard RDS."
  type        = number
  default     = 0

  validation {
    condition     = var.aurora_replica_count >= 0 && floor(var.aurora_replica_count) == var.aurora_replica_count
    error_message = "aurora_replica_count must be a non-negative whole number."
  }
}

variable "multi_az" {
  description = "Enables Multi-AZ deployment for a standard RDS instance. Aurora already distributes cluster storage across Availability Zones."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "application"
}

variable "db_username" {
  description = "Master database username."
  type        = string
  default     = "dbadmin"
}

variable "manage_master_user_password" {
  description = "When true, AWS manages the master password in Secrets Manager. When false, db_password must be supplied."
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Master database password used only when manage_master_user_password is false. Never commit a real password to Git."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true

  validation {
    condition     = var.db_password == null || length(var.db_password) >= 8
    error_message = "The database password must contain at least 8 characters."
  }
}

variable "port" {
  description = "Database port. When null, the module uses 5432 for PostgreSQL or 3306 for MySQL."
  type        = number
  default     = null
  nullable    = true
}

variable "parameters" {
  description = "Optional custom parameter map. When null, PostgreSQL receives max_connections, log_statement, and work_mem defaults; MySQL receives compatible defaults."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "allocated_storage" {
  description = "Initial storage in GiB for a standard RDS instance. Ignored for Aurora."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage > 0
    error_message = "allocated_storage must be greater than zero."
  }
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB for a standard RDS instance. Set to 0 to disable storage autoscaling. Ignored for Aurora."
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage >= 0
    error_message = "max_allocated_storage must be zero or greater."
  }
}

variable "storage_type" {
  description = "Storage type for a standard RDS instance. Ignored for Aurora."
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enables storage encryption."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ARN or ID used for database storage encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0
    error_message = "backup_retention_period must be zero or greater."
  }
}

variable "publicly_accessible" {
  description = "Whether DB instances receive a public endpoint. When true, subnet_public_ids must contain at least two subnets."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevents accidental deletion when true."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skips the final snapshot during deletion. Suitable for training; production databases should normally set this to false."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Applies database modifications immediately instead of waiting for the maintenance window."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Allows automatic minor engine version upgrades during the maintenance window."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags added to all resources created by the module."
  type        = map(string)
  default     = {}
}
