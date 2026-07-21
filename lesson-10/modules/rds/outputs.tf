output "mode" {
  description = "Created database mode: aurora or rds."
  value       = var.use_aurora ? "aurora" : "rds"
}

output "engine" {
  description = "Effective AWS database engine."
  value       = local.effective_engine
}

output "engine_version" {
  description = "Effective engine version."
  value       = local.effective_engine_version
}

output "endpoint" {
  description = "Writer endpoint for Aurora or hostname for the standard RDS instance."
  value = var.use_aurora ? (
    aws_rds_cluster.this[0].endpoint
    ) : (
    aws_db_instance.this[0].address
  )
}

output "reader_endpoint" {
  description = "Aurora reader endpoint. Null for a standard RDS instance."
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "port" {
  description = "Database port."
  value       = local.database_port
}

output "database_name" {
  description = "Initial database name."
  value       = var.db_name
}

output "resource_identifier" {
  description = "Aurora cluster identifier or standard RDS instance identifier."
  value = var.use_aurora ? (
    aws_rds_cluster.this[0].cluster_identifier
    ) : (
    aws_db_instance.this[0].identifier
  )
}

output "aurora_writer_identifier" {
  description = "Aurora writer instance identifier. Null for a standard RDS instance."
  value       = var.use_aurora ? aws_rds_cluster_instance.writer[0].identifier : null
}

output "aurora_reader_identifiers" {
  description = "Aurora reader instance identifiers. Empty for standard RDS or when no replicas are requested."
  value       = aws_rds_cluster_instance.readers[*].identifier
}

output "aurora_instance_count" {
  description = "Total number of Aurora instances, including one writer. Zero for standard RDS."
  value       = var.use_aurora ? 1 + var.aurora_replica_count : 0
}

output "db_subnet_group_name" {
  description = "Created DB subnet group name."
  value       = aws_db_subnet_group.this.name
}

output "security_group_id" {
  description = "Created database security group ID."
  value       = aws_security_group.this.id
}

output "parameter_group_name" {
  description = "Created standard DB parameter group or Aurora cluster parameter group name."
  value = var.use_aurora ? (
    aws_rds_cluster_parameter_group.this[0].name
    ) : (
    aws_db_parameter_group.this[0].name
  )
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing the managed master password, or null when password management is disabled."
  value = var.manage_master_user_password ? (
    var.use_aurora ? try(aws_rds_cluster.this[0].master_user_secret[0].secret_arn, null) : try(aws_db_instance.this[0].master_user_secret[0].secret_arn, null)
  ) : null
  sensitive = true
}
