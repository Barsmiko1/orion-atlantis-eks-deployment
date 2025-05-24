output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_admin_role_arn" {
  description = "The ARN of the EKS admin role"
  value       = module.iam_roles.eks_admin_role_arn
}

output "eks_readonly_role_arn" {
  description = "The ARN of the EKS read-only role"
  value       = module.iam_roles.eks_readonly_role_arn
}

output "atlantis_iam_role_arn" {
  description = "The ARN of the IAM role for Atlantis"
  value       = module.iam_roles.atlantis_iam_role_arn
}

output "atlantis_deployment_commands" {
  description = "Commands to manually deploy Atlantis after Terraform completes"
  value = <<-EOT
# Run these commands after terraform apply completes:

# 1. Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name ${module.eks.cluster_name}

# 2. Create namespace
kubectl create namespace atlantis

# 3. Create GitHub secret (replace values with your actual credentials)
kubectl create secret generic atlantis-github \
  --namespace atlantis \
  --from-literal=ATLANTIS_GH_USER="your-github-username" \
  --from-literal=ATLANTIS_GH_TOKEN="your-github-token" \
  --from-literal=ATLANTIS_GH_WEBHOOK_SECRET="your-webhook-secret"

# 4. Add Helm repo
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm repo update

# 5. Deploy Atlantis
helm install atlantis runatlantis/atlantis \
  --namespace atlantis \
  --set orgAllowlist="github.com/Barsmiko1/*" \
  --set github.user="your-github-username" \
  --set github.token="your-github-token" \
  --set github.secret="your-webhook-secret" \
  --set service.type=LoadBalancer \
  --set volumeClaim.enabled=true \
  --set volumeClaim.dataStorage=8Gi \
  --set volumeClaim.storageClassName=gp2 \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${module.iam_roles.atlantis_iam_role_arn}"

# 6. Get Atlantis URL
kubectl get service atlantis -n atlantis
  EOT
}