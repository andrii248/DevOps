output "namespace" {
  value = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "application_name" {
  value = var.application_name
}
