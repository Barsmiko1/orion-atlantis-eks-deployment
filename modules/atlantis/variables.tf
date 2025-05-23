variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "atlantis_github_user" {
  description = "GitHub username for Atlantis"
  type        = string
}

variable "atlantis_github_token" {
  description = "GitHub token for Atlantis"
  type        = string
  sensitive   = true
}

variable "atlantis_repo_allowlist" {
  description = "List of repositories that Atlantis will work with"
  type        = string
}

variable "atlantis_webhook_secret" {
  description = "Secret for GitHub webhooks"
  type        = string
  sensitive   = true
}

variable "atlantis_iam_role_arn" {
  description = "IAM role ARN for Atlantis service account"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
