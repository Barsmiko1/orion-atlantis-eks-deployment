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
  timeout    = 600
  
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
      storageClassName: "gp2"
    
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
    
    repoConfig: |
      repos:
      - id: github.com/Barsmiko1/orion-atlantis-eks-deployment
        apply_requirements: ["approved"]
        allowed_overrides: ["apply_requirements", "workflow"]
        workflow: simple
      
      workflows:
        simple:
          plan:
            steps:
            - init
            - run: |
                # Create terraform.tfvars with all variables
                cat > terraform.tfvars << EOF
                atlantis_github_user    = "$ATLANTIS_GH_USER"
                atlantis_github_token   = "$ATLANTIS_GH_TOKEN"
                atlantis_repo_allowlist = "$ATLANTIS_REPO_ALLOWLIST"
                atlantis_webhook_secret = "$ATLANTIS_GH_WEBHOOK_SECRET"
                aws_region              = "us-west-2"
                vpc_name                = "atlantis-vpc"
                vpc_cidr                = "10.0.0.0/16"
                azs                     = ["us-west-2a", "us-west-2b"]
                private_subnets         = ["10.0.1.0/24", "10.0.2.0/24"]
                public_subnets          = ["10.0.101.0/24", "10.0.102.0/24"]
                cluster_name            = "atlantis-cluster"
                min_size                = 1
                max_size                = 2
                desired_size            = 1
                instance_types          = ["t3.medium"]
                EOF
                
                echo "✅ terraform.tfvars created - ready for plan"
            - plan
          apply:
            steps:
            - init
            - run: |
                # Create terraform.tfvars with all variables
                cat > terraform.tfvars << EOF
                atlantis_github_user    = "$ATLANTIS_GH_USER"
                atlantis_github_token   = "$ATLANTIS_GH_TOKEN"
                atlantis_repo_allowlist = "$ATLANTIS_REPO_ALLOWLIST"
                atlantis_webhook_secret = "$ATLANTIS_GH_WEBHOOK_SECRET"
                aws_region              = "us-west-2"
                vpc_name                = "atlantis-vpc"
                vpc_cidr                = "10.0.0.0/16"
                azs                     = ["us-west-2a", "us-west-2b"]
                private_subnets         = ["10.0.1.0/24", "10.0.2.0/24"]
                public_subnets          = ["10.0.101.0/24", "10.0.102.0/24"]
                cluster_name            = "atlantis-cluster"
                min_size                = 1
                max_size                = 2
                desired_size            = 1
                instance_types          = ["t3.medium"]
                EOF
            - apply
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