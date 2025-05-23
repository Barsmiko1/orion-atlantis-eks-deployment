variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The URL of the OIDC issuer for the EKS cluster"
  type        = string
}
