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

# Remove atlantis_url output since we removed the atlantis module

output "atlantis_iam_role_arn" {
  description = "The ARN of the IAM role for Atlantis"
  value       = module.iam_roles.atlantis_iam_role_arn
}

# Add helpful commands for manual Atlantis deployment
output "manual_atlantis_commands" {
  description = "Commands to manually deploy Atlantis after Terraform completes"
  value = <<-EOT
    # After terraform apply completes, run these commands to deploy Atlantis:
    
    1. Update your kubeconfig:
       aws eks update-kubeconfig --region us-west-2 --name ${module.eks.cluster_name}
    
    2. Create Atlantis namespace:
       kubectl create namespace atlantis
    
    3. Create GitHub secret:
       kubectl create secret generic atlantis-github \
         --namespace atlantis \
         --from-literal=ATLANTIS_GH_USER="$${var.atlantis_github_user}" \
         --from-literal=ATLANTIS_GH_TOKEN="$${var.atlantis_github_token}" \
         --from-literal=ATLANTIS_GH_WEBHOOK_SECRET="$${var.atlantis_webhook_secret}"
    
    4. Deploy Atlantis with Helm:
       helm repo add runatlantis https://runatlantis.github.io/helm-charts
       helm repo update
       helm install atlantis runatlantis/atlantis \
         --namespace atlantis \
         --set orgAllowlist="${var.atlantis_repo_allowlist}" \
         --set github.user="${var.atlantis_github_user}" \
         --set github.token="${var.atlantis_github_token}" \
         --set github.secret="${var.atlantis_webhook_secret}" \
         --set service.type=LoadBalancer \
         --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${module.iam_roles.atlantis_iam_role_arn}"
    
    5. Get Atlantis URL:
       kubectl get service atlantis -n atlantis
  EOT
}