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

data "aws_caller_identity" "current" {}
