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
    # Configure service account with IAM role annotation
    serviceAccount:
      create: true
      annotations:
        eks.amazonaws.com/role-arn: "${var.atlantis_iam_role_arn}"
    # Set environment variables
    environment:
      ATLANTIS_REPO_ALLOWLIST: "${var.atlantis_repo_allowlist}"
      AWS_REGION: "${var.aws_region}"
    # Set environment secrets
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
    # Use custom repo config directly in the Helm values
    repoConfig: |
      repos:
      - id: github.com/Barsmiko1/orion-atlantis-eks-deployment
        workflow: custom
        allowed_overrides: [workflow, apply_requirements]
        allow_custom_workflows: true
      
      workflows:
        custom:
          plan:
            steps:
            - env:
                name: ATLANTIS_TERRAFORM_VARS
                command: 'echo "-var atlantis_github_user=$$ATLANTIS_GH_USER -var atlantis_github_token=$$ATLANTIS_GH_TOKEN -var atlantis_repo_allowlist=$$ATLANTIS_REPO_ALLOWLIST -var atlantis_webhook_secret=$$ATLANTIS_GH_WEBHOOK_SECRET"'
            - init
            - run: terraform plan $$(eval $$ATLANTIS_TERRAFORM_VARS)
          apply:
            steps:
            - env:
                name: ATLANTIS_TERRAFORM_VARS
                command: 'echo "-var atlantis_github_user=$$ATLANTIS_GH_USER -var atlantis_github_token=$$ATLANTIS_GH_TOKEN -var atlantis_repo_allowlist=$$ATLANTIS_REPO_ALLOWLIST -var atlantis_webhook_secret=$$ATLANTIS_GH_WEBHOOK_SECRET"'
            - init
            - run: terraform apply $$(eval $$ATLANTIS_TERRAFORM_VARS)
    EOT
  ]
  
  depends_on = [
    kubernetes_namespace.atlantis,
    kubernetes_secret.atlantis_github
  ]
}

data "kubernetes_service" "atlantis" {
  metadata {
    name      = "atlantis"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }
  
  depends_on = [helm_release.atlantis]
}
