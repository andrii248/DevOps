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