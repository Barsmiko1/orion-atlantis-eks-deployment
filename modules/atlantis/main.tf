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

resource "helm_release" "atlantis" {
  name       = "atlantis"
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  namespace  = kubernetes_namespace.atlantis.metadata[0].name
  timeout    = 900  // 15 minutes
  
  # Use values file for more complex configuration
  values = [
    <<-EOT
    orgAllowlist: "${var.atlantis_repo_allowlist}"
    github:
      user: "${var.atlantis_github_user}"
      token: "${var.atlantis_github_token}"
      secret: "${var.atlantis_webhook_secret}"
    service:
      type: LoadBalancer
    # Use the correct storage configuration based on values.yaml
    volumeClaim:
      enabled: true
      dataStorage: 8Gi
      storageClassName: "ebs-sc"
    repoConfig: |
      repos:
      - id: /.*/
        workflow: default
        allowed_overrides: [workflow]
        allow_custom_workflows: true
    EOT
  ]
  
  depends_on = [
    kubernetes_namespace.atlantis
  ]
}

data "kubernetes_service" "atlantis" {
  metadata {
    name      = "atlantis"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }
  
  depends_on = [helm_release.atlantis]
}
