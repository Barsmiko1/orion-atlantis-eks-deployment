resource "kubernetes_namespace" "atlantis" {
  metadata {
    name = "atlantis"
  }
}

resource "kubernetes_secret" "atlantis_github" {
  metadata {
    name      = "atlantis-github"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }
  
  data = {
    ATLANTIS_GH_USER           = var.atlantis_github_user
    ATLANTIS_GH_TOKEN          = var.atlantis_github_token
    ATLANTIS_GH_WEBHOOK_SECRET = var.atlantis_webhook_secret
  }
}

# Create AWS credentials secret for Atlantis
resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }
  
  data = {
    AWS_REGION = var.aws_region
  }
}

resource "helm_release" "atlantis" {
  name       = "atlantis"
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  namespace  = kubernetes_namespace.atlantis.metadata[0].name
  timeout    = 600  // Reduced to 10 minutes
  
  values = [
    <<-EOT
    orgAllowlist: "${var.atlantis_repo_allowlist}"
    
    github:
      user: "${var.atlantis_github_user}"
      token: "${var.atlantis_github_token}"
      secret: "${var.atlantis_webhook_secret}"
    
    service:
      type: LoadBalancer
    
    volumeClaim:
      enabled: true
      dataStorage: 8Gi
      storageClassName: "ebs-sc"
    
    serviceAccount:
      create: true
      annotations:
        eks.amazonaws.com/role-arn: "${var.atlantis_iam_role_arn}"
    
    environment:
      ATLANTIS_REPO_ALLOWLIST: "${var.atlantis_repo_allowlist}"
      AWS_REGION: "${var.aws_region}"
    
    environmentSecrets:
      - name: ATLANTIS_GH_USER
        secretKeyRef:
          name: atlantis-github
          key: ATLANTIS_GH_USER
      - name: ATLANTIS_GH_TOKEN
        secretKeyRef:
          name: atlantis-github
          key: ATLANTIS_GH_TOKEN
      - name: ATLANTIS_GH_WEBHOOK_SECRET
        secretKeyRef:
          name: atlantis-github
          key: ATLANTIS_GH_WEBHOOK_SECRET
    
    # Simplified repo config without complex workflows
    repoConfig: |
      repos:
      - id: github.com/Barsmiko1/orion-atlantis-eks-deployment
        apply_requirements: ["approved"]
        allowed_overrides: ["apply_requirements"]
    EOT
  ]
  
  depends_on = [
    kubernetes_namespace.atlantis,
    kubernetes_secret.atlantis_github,
    kubernetes_secret.aws_credentials
  ]
}

data "kubernetes_service" "atlantis" {
  metadata {
    name      = "atlantis"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }
  
  depends_on = [helm_release.atlantis]
}