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

output "atlantis_url" {
  description = "The URL of the Atlantis service"
  value       = module.atlantis.atlantis_url
}

output "atlantis_iam_role_arn" {
  description = "The ARN of the IAM role for Atlantis"
  value       = module.iam_roles.atlantis_iam_role_arn
}
