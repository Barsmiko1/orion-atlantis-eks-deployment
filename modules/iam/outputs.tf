output "eks_admin_role_arn" {
  description = "The ARN of the EKS admin role"
  value       = aws_iam_role.eks_admin.arn
}

output "eks_readonly_role_arn" {
  description = "The ARN of the EKS read-only role"
  value       = aws_iam_role.eks_readonly.arn
}

output "atlantis_iam_role_arn" {
  description = "The ARN of the IAM role for Atlantis"
  value       = aws_iam_role.atlantis.arn
}
