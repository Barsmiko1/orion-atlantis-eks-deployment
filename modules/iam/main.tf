resource "aws_iam_role" "eks_admin" {
  name = "${var.cluster_name}-eks-admin"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "eks_admin" {
  name = "${var.cluster_name}-eks-admin-policy"
  role = aws_iam_role.eks_admin.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "eks_readonly" {
  name = "${var.cluster_name}-eks-readonly"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "eks_readonly" {
  name = "${var.cluster_name}-eks-readonly-policy"
  role = aws_iam_role.eks_readonly.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListFargateProfiles",
          "eks:ListAddons",
          "eks:DescribeAddon"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Create Kubernetes RBAC configuration for the admin role
resource "kubernetes_cluster_role_binding" "admin" {
  metadata {
    name = "eks-admin-binding"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  
  subject {
    kind      = "User"
    name      = "eks-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Create Kubernetes RBAC configuration for the read-only role
resource "kubernetes_cluster_role_binding" "readonly" {
  metadata {
    name = "eks-readonly-binding"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
  
  subject {
    kind      = "User"
    name      = "eks-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
}

# IAM role for Atlantis to assume via IRSA
resource "aws_iam_role" "atlantis" {
  name = "${var.cluster_name}-atlantis-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_oidc_issuer_url, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:atlantis:atlantis"
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.cluster_name}-atlantis-role"
  }
}

# IAM policy for Atlantis with necessary permissions
resource "aws_iam_policy" "atlantis" {
  name        = "${var.cluster_name}-atlantis-policy"
  description = "IAM policy for Atlantis to manage AWS resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 permissions for VPC, subnets, security groups, etc.
          "ec2:*",
          
          # EKS permissions
          "eks:*",
          
          # IAM permissions
          "iam:*",
          
          # S3 permissions for Terraform state (to access S3 backend)
          "s3:*",
          
          # DynamoDB permissions for state locking (to access DynamoDB)
          "dynamodb:*",
          
          # CloudFormation permissions (EKS to use CloudFormation)
          "cloudformation:*",
          
          # Auto Scaling permissions
          "autoscaling:*",
          
          # Application Load Balancer permissions
          "elasticloadbalancing:*",
          
          # Route53 permissions ( managing DNS)
          "route53:*",
          
          # CloudWatch permissions
          "logs:*",
          "cloudwatch:*",
          
          # KMS permissions (for encryption)
          "kms:*",
          
          # SSM permissions (for parameter store)
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "atlantis" {
  role       = aws_iam_role.atlantis.name
  policy_arn = aws_iam_policy.atlantis.arn
}

data "aws_caller_identity" "current" {}
