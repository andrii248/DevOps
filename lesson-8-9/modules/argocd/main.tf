resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  create_namespace = false
  timeout          = 1200
  wait             = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace_v1.argocd
  ]
}

resource "helm_release" "application" {
  name      = "django-app-application"
  chart     = "${path.module}/application"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name

  timeout         = 300
  wait            = true
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      application = {
        name                 = var.application_name
        repoURL              = var.gitops_repository_url
        targetRevision       = var.gitops_revision
        path                 = var.gitops_chart_path
        destinationNamespace = var.application_namespace
      }
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}
