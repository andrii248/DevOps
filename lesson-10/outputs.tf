/*
output "backend_s3_bucket_url" {
  value = module.s3_backend.s3_bucket_url
}

output "backend_dynamodb_table_name" {
  value = module.s3_backend.dynamodb_table_name
}
*/

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.eks.cluster_ca_certificate
}

output "database_mode" {
  description = "Created database mode."
  value       = module.rds.mode
}

output "database_engine" {
  description = "Effective AWS database engine."
  value       = module.rds.engine
}

output "database_engine_version" {
  description = "Effective database engine version."
  value       = module.rds.engine_version
}

output "database_endpoint" {
  description = "Database writer endpoint or RDS hostname."
  value       = module.rds.endpoint
}

output "database_reader_endpoint" {
  description = "Aurora reader endpoint, or null for standard RDS."
  value       = module.rds.reader_endpoint
}

output "database_aurora_reader_identifiers" {
  description = "Aurora reader instance identifiers."
  value       = module.rds.aurora_reader_identifiers
}

output "database_port" {
  description = "Database port."
  value       = module.rds.port
}

output "database_security_group_id" {
  description = "Security group created by the RDS module."
  value       = module.rds.security_group_id
}

output "database_subnet_group_name" {
  description = "DB subnet group created by the RDS module."
  value       = module.rds.db_subnet_group_name
}

output "database_parameter_group_name" {
  description = "Parameter group created by the RDS module."
  value       = module.rds.parameter_group_name
}

output "database_master_user_secret_arn" {
  description = "Secrets Manager ARN with the database password when AWS-managed credentials are enabled."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}
