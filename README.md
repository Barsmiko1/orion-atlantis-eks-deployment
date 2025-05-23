## orion-atlantis-eks-deployment


# Atlantis on AWS EKS

This repository contains Terraform configurations to deploy Atlantis on AWS EKS. Atlantis is a tool for automating Terraform pull request workflows.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.0.0 or newer
- kubectl
- helm
- eksctl

## Infrastructure Overview

This deployment creates:

- 1 VPC with 2 private and 2 public subnets across 2 availability zones
- 1 EKS cluster
- Node group with autoscaling (min: 1, max: 2)
- IAM roles for Kubernetes RBAC:
  - eks-admin: Full administrative privileges
  - eks-readonly: Read-only access
- Atlantis deployment via Helm

## Deployment Steps

1. ```console
   git clone https://github.com/Barsmiko1/orion-atlantis-eks-deployment.git
   cd orion-atlantis-eks-deployment
   \`\`\`

2. Create a `terraform.tfvars` file with the desired configuration:
   \`\`\`
 

3. Edit the `terraform.tfvars` file to set your GitHub credentials and other variables:
   \`\`\`
   atlantis_github_user = "your-github-username"
   atlantis_github_token = "your-github-token"
   atlantis_repo_allowlist = "github.com/your-username/*"
   atlantis_webhook_secret = "your-webhook-secret"
   \`\`\`

4. Initialize Terraform:
   \`\`\`
   terraform init
   \`\`\`

5. Plan the deployment:
   \`\`\`
   terraform plan
   \`\`\`

6. Apply the configuration:
   \`\`\`
   terraform apply
   \`\`\`

7. Configure kubectl to connect to your EKS cluster:
   \`\`\`
   aws eks update-kubeconfig --region us-west-2 --name atlantis-cluster
   \`\`\`

8. Verify the Atlantis deployment:
   \`\`\`
   kubectl get pods -n atlantis
   \`\`\`

9. Get the Atlantis URL:
   \`\`\`
   terraform output atlantis_url
   \`\`\`

## Setting up GitHub Webhook

1. Go to your GitHub repository settings
2. Navigate to "Webhooks" and click "Add webhook"
3. Set the Payload URL to your Atlantis URL (from the terraform output)
4. Set the Content type to "application/json"
5. Set the Secret to the same value as `atlantis_webhook_secret` in the terraform.tfvars
6. Select "Let me select individual events" and check:
   - Pull requests
   - Issue comments
   - Pushes
7. Click "Add webhook"

## Testing the Integration

1. Create a new branch in your repository
2. Make a change to a Terraform file
3. Create a pull request
4. Atlantis should automatically comment on the PR with the plan output
5. Comment "atlantis apply" to apply the changes

## Cleanup

To destroy all resources created by this configuration:

\`\`\`
terraform destroy
\`\`\`

## IAM Role Usage

To assume the eks-admin role:
\`\`\`
aws eks update-kubeconfig --region us-west-2 --name atlantis-cluster --role-arn $(terraform output -raw eks_admin_role_arn)
\`\`\`

To assume the eks-readonly role:
\`\`\`
aws eks update-kubeconfig --region us-west-2 --name atlantis-cluster --role-arn $(terraform output -raw eks_readonly_role_arn)
