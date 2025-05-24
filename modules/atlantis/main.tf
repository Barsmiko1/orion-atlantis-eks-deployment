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
      storageClassName: "ebs-sc"
    
    serviceAccount:
      create: true
      annotations:
        eks.amazonaws.com/role-arn: "${var.atlantis_iam_role_arn}"
    
    environment:
      ATLANTIS_REPO_ALLOWLIST: "${var.atlantis_repo_allowlist}"
      AWS_REGION: "${var.aws_region}"
    
    # Add init container to install tools as root
    initContainers:
    - name: install-tools
      image: alpine:latest
      securityContext:
        runAsUser: 0
        runAsGroup: 0
      command:
      - /bin/sh
      - -c
      - |
        set -e
        echo "Starting tool installation as root..."
        
        # Create shared bin directory
        mkdir -p /shared/bin
        
        # Update package index and install dependencies
        apk update
        apk add --no-cache curl unzip python3 py3-pip
        
        # Install AWS CLI via pip
        echo "Installing AWS CLI..."
        pip3 install awscli --break-system-packages
        cp $(which aws) /shared/bin/aws
        
        # Install kubectl
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /shared/bin/kubectl
        
        # Make executables
        chmod +x /shared/bin/aws /shared/bin/kubectl
        
        # Verify installations
        echo "Verifying installations..."
        /shared/bin/aws --version
        /shared/bin/kubectl version --client
        
        echo "✅ Tools installation completed successfully!"
      volumeMounts:
      - name: shared-tools
        mountPath: /shared
    
    # Add shared volume for tools
    extraVolumes:
    - name: shared-tools
      emptyDir: {}
    
    extraVolumeMounts:
    - name: shared-tools
      mountPath: /atlantis-tools
      subPath: bin
    
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
        workflow: secure
      
      workflows:
        secure:
          plan:
            steps:
            - init
            - run: |
                # Create terraform.tfvars with secrets from environment and config from repo
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
                
                # Verify tools are available
                echo "Checking tool availability..."
                export PATH=$PATH:/atlantis-tools
                which aws || echo "❌ AWS CLI not found in PATH"
                which kubectl || echo "❌ kubectl not found in PATH"
                
                # Show PATH for debugging
                echo "Current PATH: $PATH"
                ls -la /atlantis-tools/ || echo "No /atlantis-tools directory"
            - plan
          apply:
            steps:
            - init
            - run: |
                # Create terraform.tfvars with secrets from environment and config from repo
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