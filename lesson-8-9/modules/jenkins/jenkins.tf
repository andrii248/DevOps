resource "kubernetes_namespace_v1" "jenkins" {
  metadata {
    name = var.namespace
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:jenkins-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "${var.cluster_name}-jenkins-ecr"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "jenkins" {
  name = "${var.cluster_name}-jenkins-ecr"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "kubernetes_service_account_v1" "jenkins" {
  metadata {
    name      = "jenkins-sa"
    namespace = kubernetes_namespace_v1.jenkins.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins.arn
    }
  }
}

resource "kubernetes_secret_v1" "github" {
  metadata {
    name      = "jenkins-github-token"
    namespace = kubernetes_namespace_v1.jenkins.metadata[0].name
  }

  type = "Opaque"

  data = {
    "github-token" = var.github_token
  }
}

resource "kubernetes_storage_class_v1" "ebs" {
  metadata {
    name = "ebs-sc"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  namespace        = kubernetes_namespace_v1.jenkins.metadata[0].name
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.chart_version
  create_namespace = false

  timeout         = 1200
  wait            = true
  atomic          = true
  cleanup_on_fail = true

  values = [
    templatefile("${path.module}/values.yaml", {
      app_repository_url = var.app_repository_url
      github_owner       = var.github_owner
    })
  ]

  depends_on = [
    aws_iam_role_policy.jenkins,
    kubernetes_service_account_v1.jenkins,
    kubernetes_secret_v1.github,
    kubernetes_storage_class_v1.ebs
  ]
}
