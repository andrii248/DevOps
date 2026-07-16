output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "CA certificate for the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}
output "oidc_provider_arn" {
  description = "ARN of the EKS IAM OIDC provider"
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_provider_url" {
  description = "URL of the EKS IAM OIDC provider"
  value       = aws_iam_openid_connect_provider.main.url
}
