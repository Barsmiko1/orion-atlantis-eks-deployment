  ## Orion Task Atlantis Deployment  on AWS EKS - Deployment Guide
  ## Author 🚀: John Michael Chukwudi

A comprehensive guide to deploy the Atlantis software on AWS EKS using Terraform and helm for automated infrastructure management through GitHub pull requests.

![Atlantis Architecture](https://www.runatlantis.io/hero.png)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Atlantis Setup](#atlantis-setup)
- [GitHub Integration](#github-integration)
- [Testing & Verification](#testing--verification)
- [Operations & Maintenance](#operations--maintenance)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Cost Optimization](#cost-optimization)
- [Contributing](#contributing)
- [References](#references)

## 🎯 Overview

This project deploys **Atlantis** - a tool for automating Terraform pull request workflows - on **Amazon EKS**. Atlantis allows teams to collaborate on infrastructure changes through GitHub pull requests, providing automated planning, reviewing, and applying of Terraform configurations.

### What You'll Build

- **AWS VPC** with public and private subnets across multiple availability zones
- **Amazon EKS cluster** with managed node groups
- **IAM roles and policies** for secure access and service integration
- **Atlantis deployment** for automated Terraform workflows
- **GitHub webhook integration** for pull request automation

### Key Benefits

- 🔄 **Automated Infrastructure Reviews**: See Terraform plans directly in pull requests
- 🛡️ **Enhanced Security**: Role-based access control and approval workflows
- 👥 **Team Collaboration**: Infrastructure changes through familiar Git workflows
- 📊 **Audit Trail**: Complete history of infrastructure changes in Git
- 🚀 **CI/CD Integration**: Seamless integration with existing development workflows

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Account                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                    │   │
│  │                                                         │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │ Public Subnet│  │ Public Subnet│  │              │  │   │
│  │  │ us-west-2a   │  │ us-west-2b   │  │   Internet   │  │   │
│  │  │10.0.101.0/24 │  │10.0.102.0/24 │  │   Gateway    │  │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────────────┘  │   │
│  │         │                 │                            │   │
│  │  ┌──────▼───────┐  ┌──────▼───────┐                    │   │
│  │  │  NAT Gateway │  │  NAT Gateway │                    │   │
│  │  └──────┬───────┘  └──────┬───────┘                    │   │
│  │         │                 │                            │   │
│  │  ┌──────▼───────┐  ┌──────▼───────┐                    │   │
│  │  │Private Subnet│  │Private Subnet│                    │   │
│  │  │ us-west-2a   │  │ us-west-2b   │                    │   │
│  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │                    │   │
│  │  │              │  │              │                    │   │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │                    │   │
│  │  │ │EKS Nodes │ │  │ │EKS Nodes │ │                    │   │
│  │  │ └──────────┘ │  │ └──────────┘ │                    │   │
│  │  └──────────────┘  └──────────────┘                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 EKS Control Plane                      │   │
│  │                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │  Atlantis   │  │    EBS CSI  │  │   Other     │     │   │
│  │  │    Pod      │  │   Driver    │  │  Add-ons    │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          GitHub                                 │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Repository                           │   │
│  │                                                         │   │
│  │  Pull Request ──► Webhook ──► Atlantis ──► Terraform    │   │
│  │       │                                        │        │   │
│  │       ▼                                        ▼        │   │
│  │  Plan Comment ◄──────────────────────── AWS Resources  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Component Details

- **VPC**: Isolated network environment with public/private subnet architecture
- **EKS**: Managed Kubernetes service for container orchestration
- **Atlantis**: Terraform automation tool running as Kubernetes deployment
- **IAM**: Role-based access control with least privilege principles
- **GitHub**: Source code management and webhook integration

## 📋 Prerequisites

### Required Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **AWS CLI** | ≥ 2.0 | AWS resource management | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **Terraform** | ≥ 1.0 | Infrastructure as Code | [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli) |
| **kubectl** | ≥ 1.24 | Kubernetes cluster management | [Install Guide](https://kubernetes.io/docs/tasks/tools/) |
| **Helm** | ≥ 3.0 | Kubernetes package management | [Install Guide](https://helm.sh/docs/intro/install/) |
| **Git** | ≥ 2.0 | Version control | [Install Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) |

### AWS Account Requirements

- **AWS Account** with administrative access
- **AWS CLI configured** with appropriate credentials
- **S3 bucket** for Terraform state storage (will be created)
- **Sufficient AWS service limits** for EKS, EC2, and VPC resources

### GitHub Requirements

- **GitHub account** with repository access
- **Personal Access Token** with required permissions:
  - `repo` (Full control of private repositories)
  - `admin:repo_hook` (Full control of repository hooks)
  - `user` (Read user profile data)

### Knowledge Prerequisites

- Basic understanding of AWS services (VPC, EKS, IAM)
- Familiarity with Terraform concepts
- Basic Kubernetes knowledge
- Git workflow understanding

## 📁 Project Structure

```
orion-atlantis-eks-deployment/
├── README.md                          # This comprehensive guide
├── .gitignore                         # Git ignore patterns
├── backend.tf                         # Terraform backend configuration
├── main.tf                            # Main Terraform configuration
├── variables.tf                       # Variable definitions
├── outputs.tf                         # Output definitions
├── terraform.tfvars                   # Your actual variables (not in git)
│
├── modules/                          # Reusable Terraform modules
│   ├── vpc/                          # VPC module
│   │   ├── main.tf                   # VPC resources
│   │   ├── variables.tf              # VPC variables
│   │   └── outputs.tf                # VPC outputs
│   ├── eks/                          # EKS module
│   │   ├── main.tf                   # EKS cluster and node group
│   │   ├── variables.tf              # EKS variables
│   │   └── outputs.tf                # EKS outputs
│   └── iam/                          # IAM module
│       ├── main.tf                   # IAM roles and policies
│       ├── variables.tf              # IAM variables
│       └── outputs.tf                # IAM outputs
│
├── docs/                             # Additional documentation
│   ├── architecture.md               # Detailed architecture guide
│   ├── security.md                   # Security best practices
│   └── troubleshooting.md             # Common issues and solutions
│
└── scripts/                          # Utility scripts
    ├── setup-prerequisites.sh        # Install required tools
    ├── deploy-atlantis.sh             # Automated Atlantis deployment
    └── cleanup.sh                     # Resource cleanup script
```

## 🚀 Getting Started

### Step 1: Environment Setup

#### 1.1 Verify Prerequisites


# Check AWS CLI
```console
aws --version
aws sts get-caller-identity
```

# Check Terraform
```console
terraform version
```

# Check kubectl
```console
kubectl version --client
```

# Check Helm
```console
helm version
```

# Check Git
```console
git --version
```

#### 1.2 Clone the Repository


# Clone the repository
```console
git clone https://github.com/Barsmiko1/orion-atlantis-eks-deployment.git
cd orion-atlantis-eks-deployment
```

# Verify project structure
```console
ls -la
```

#### 1.3 Set Up AWS Credentials

# Configure AWS CLI (if not already configured)
```console
aws configure
```

# Verify access
```console
aws sts get-caller-identity
```

### Step 2: Create GitHub Personal Access Token

#### 2.1 Generate Token

1. Navigate to GitHub → Settings → Developer settings → Personal access tokens
2. Click "Generate new token (classic)"
3. Select required scopes:
   - ✅ `repo` - Full control of private repositories
   - ✅ `admin:repo_hook` - Full control of repository hooks
   - ✅ `user` - Read user profile data
4. Generate and save the token securely

#### 2.2 Test Token

# Test GitHub API access
```console
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://api.github.com/user
```

### Step 3: Configure Terraform Backend

#### 3.1 Create S3 Bucket for State


# Create S3 bucket for Terraform state
```console
aws s3 mb s3://your-terraform-state-bucket-unique-name
```

# Enable versioning
```console
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket-unique-name \
  --versioning-configuration Status=Enabled
```
# Enable encryption
```console
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket-unique-name \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

#### 3.2 Update Backend Configuration

vim `backend.tf`:

```console
terraform {
  backend "s3" {
    bucket  = "your-terraform-state-bucket-unique-name"
    key     = "dev/terraform-dev-state/dev.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
```

## ⚙️ Configuration

### Step 1: Configure Variables

#### 1.1 Copy Example Variables

```console
cp terraform.tfvars.example terraform.tfvars
```

#### 1.2 Edit terraform.tfvars

```console
# Infrastructure Configuration
aws_region              = "us-west-2"
vpc_name                = "atlantis-vpc"
vpc_cidr                = "10.0.0.0/16"
azs                     = ["us-west-2a", "us-west-2b"]
private_subnets         = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets          = ["10.0.101.0/24", "10.0.102.0/24"]
cluster_name            = "atlantis-cluster"

# EKS Node Group Configuration
min_size                = 1
max_size                = 2
desired_size            = 1
instance_types          = ["t3.medium"]
```

#### 1.3 Set Environment Variables for Atlantis


# Create .env file for Atlantis deployment (not tracked in git)
cat > .env << EOF
ATLANTIS_GH_USER=your-github-username
ATLANTIS_GH_TOKEN=your-github-token
ATLANTIS_REPO_ALLOWLIST=github.com/your-username/*
ATLANTIS_WEBHOOK_SECRET=your-webhook-secret
EOF

# Source the environment variables
```console
source .env
```

### Step 2: Validate Configuration

# Initialize Terraform
```console
terraform init
```
# Validate configuration
```console
terraform validate
```

# Check formatting
```console
terraform fmt -check
```

# Plan deployment (dry run)
```console
terraform plan -var-file=terraform.tfvars
```

## 🚢 Deployment

### Phase 1: Infrastructure Deployment

#### 1.1 Deploy AWS Infrastructure

# Initialize Terraform (if not done already)
```console
terraform init
```
# Review the execution plan
```console
terraform plan -var-file=terraform.tfvars
```

# Apply the configuration
```console
terraform apply -var-file=terraform.tfvars
```

**Expected Duration**: 15-20 minutes

**What's Being Created**:
- VPC with public and private subnets
- Internet Gateway and NAT Gateways
- EKS cluster and managed node group
- IAM roles and policies
- EBS CSI driver add-on

#### 1.2 Verify Infrastructure

# Check VPC
```console
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=atlantis-vpc"
```
# Check EKS cluster
```console
aws eks describe-cluster --name atlantis-cluster
```

# Check nodes
```console
aws eks describe-nodegroup \
  --cluster-name atlantis-cluster \
  --nodegroup-name atlantis-cluster-node-group
```

### Phase 2: Kubernetes Configuration

#### 2.1 Configure kubectl

# Update kubeconfig
```console
aws eks update-kubeconfig --region us-west-2 --name atlantis-cluster
```
# Verify connection
```console
kubectl get nodes
```

# Check cluster info
```console
kubectl cluster-info
```

#### 2.2 Verify EKS Add-ons

# Check EBS CSI driver
```console
kubectl get pods -n kube-system | grep ebs-csi
```

# Check storage classes
```console
kubectl get storageclass
```
# Verify default storage class
```console
kubectl get storageclass | grep "(default)"
```

## 🤖 Atlantis Setup

### Step 1: Prepare Atlantis Deployment

#### 1.1 Create Namespace


# Create Atlantis namespace
```console
kubectl create namespace atlantis
```

# Verify namespace
```console
kubectl get namespaces | grep atlantis
```

#### 1.2 Create GitHub Secret

```console
# Create secret with GitHub credentials
kubectl create secret generic atlantis-github \
  --namespace atlantis \
  --from-literal=ATLANTIS_GH_USER="$ATLANTIS_GH_USER" \
  --from-literal=ATLANTIS_GH_TOKEN="$ATLANTIS_GH_TOKEN" \
  --from-literal=ATLANTIS_GH_WEBHOOK_SECRET="$ATLANTIS_WEBHOOK_SECRET"
  ```

# Verify secret
```console
kubectl get secret atlantis-github -n atlantis
```

### Step 2: Deploy Atlantis with Helm

#### 2.1 Add Helm Repository


# Add Atlantis Helm repository
```console
helm repo add runatlantis https://runatlantis.github.io/helm-charts
```

# Update Helm repositories
```console
helm repo update
```

# Verify repository
```console
helm search repo atlantis
```

#### 2.2 Get IAM Role ARN


# Get the Atlantis IAM role ARN from Terraform output
```console
ATLANTIS_ROLE_ARN=$(terraform output -raw atlantis_iam_role_arn)
echo "Atlantis IAM Role ARN: $ATLANTIS_ROLE_ARN"
```

#### 2.3 Deploy Atlantis

# Deploy Atlantis with Helm
```console
helm install atlantis runatlantis/atlantis \
  --namespace atlantis \
  --set orgAllowlist="$ATLANTIS_REPO_ALLOWLIST" \
  --set github.user="$ATLANTIS_GH_USER" \
  --set github.token="$ATLANTIS_GH_TOKEN" \
  --set github.secret="$ATLANTIS_WEBHOOK_SECRET" \
  --set service.type=LoadBalancer \
  --set volumeClaim.enabled=true \
  --set volumeClaim.dataStorage=8Gi \
  --set volumeClaim.storageClassName=gp2 \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ATLANTIS_ROLE_ARN" \
  --set repoConfig="repos:\n- id: github.com/$ATLANTIS_GH_USER/orion-atlantis-eks-deployment\n  apply_requirements: [\"approved\"]\n  allowed_overrides: [\"apply_requirements\", \"workflow\"]\n  allow_custom_workflows: true"

```

# Verify deployment
```console
helm list -n atlantis
```

### Step 3: Wait for Deployment

#### 3.1 Monitor Pod Status


# Watch pod status
```console
kubectl get pods -n atlantis -w
```

# Check pod logs (once running)
```console
kubectl logs -n atlantis -l app=atlantis --tail=50
```

#### 3.2 Get LoadBalancer URL

# Wait for LoadBalancer to get external IP
```console
kubectl get service atlantis -n atlantis -w
```

# Once you see EXTERNAL-IP, get the URL
```console
ATLANTIS_URL=$(kubectl get service atlantis -n atlantis -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Atlantis URL: http://$ATLANTIS_URL"
```

**Note**: It may take 5-10 minutes for the LoadBalancer to provision and become available.

## 🔗 GitHub Integration

### Step 1: Configure GitHub Webhook

#### 1.1 Navigate to Repository Settings

1. Go to your GitHub repository: `https://github.com/your-username/orion-atlantis-eks-deployment`
2. Click **Settings** tab
3. Click **Webhooks** in the left sidebar
4. Click **Add webhook**

#### 1.2 Configure Webhook

Fill in the webhook configuration:

- **Payload URL**: `http://YOUR_ATLANTIS_URL` (from previous step)
- **Content type**: `application/json`
- **Secret**: Your webhook secret (same as `ATLANTIS_WEBHOOK_SECRET`)
- **Which events would you like to trigger this webhook?**
  - Select "Let me select individual events"
  - Check: ✅ Pull requests
  - Check: ✅ Issue comments
  - Check: ✅ Pushes
- **Active**: ✅ Checked

#### 1.3 Test Webhook


# Create a test webhook delivery
```console
curl -X POST http://$ATLANTIS_URL/events \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: ping" \
  -d '{"zen": "Keep it logically awesome."}'
```


# Add to git
git add .atlantis/atlantis.yaml
git commit -m "Add Atlantis configuration"
git push origin main
```

## 🧪 Testing & Verification

### Step 1: Test Atlantis Workflow

#### 1.1 Create Test Branch

# Create a new branch for testing
```console
git checkout -b test-atlantis-deployment
```

# Make a small change to test Terraform
```console
echo "# Testing Atlantis automation" >> test.tf
```

# Commit the change
```console
git add test.tf
git commit -m "Test Atlantis automation workflow"
```

# Push the branch
```console
git push origin test-atlantis-deployment
```

#### 1.2 Create Pull Request

1. Go to your GitHub repository
2. Click **Compare & pull request** for your new branch
3. Add a descriptive title: "Test Atlantis automation workflow"
4. Create the pull request

#### 1.3 Verify Atlantis Response

Within a few minutes, you should see:

1. **Atlantis comment** with Terraform plan output
2. **Plan summary** showing what will be changed
3. **Apply button** (if you're ready to apply)



#### 1.4 Test Apply Process

1. **Review the plan** carefully
2. **Approve the pull request** (if you have branch protection rules)
3. **Comment** `atlantis apply` to apply the changes
4. **Verify** that Atlantis applies the changes and comments back

### Step 2: Verify Infrastructure

#### 2.1 Check AWS Resources


# Verify VPC
```console
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=atlantis-vpc"
```

# Check EKS cluster status
```console
aws eks describe-cluster --name atlantis-cluster --query 'cluster.status'
```

# List EKS node groups
```console
aws eks list-nodegroups --cluster-name atlantis-cluster
```

# Check IAM roles
```console
aws iam list-roles --query 'Roles[?contains(RoleName, `atlantis`)]'
```

#### 2.2 Check Kubernetes Resources

```console
# Check cluster nodes
kubectl get nodes -o wide

# Check Atlantis pod
kubectl get pods -n atlantis

# Check Atlantis service
kubectl get service atlantis -n atlantis

# Check storage classes
kubectl get storageclass
```

#### 2.3 Verify Atlantis Functionality

```console
# Check Atlantis logs
kubectl logs -n atlantis -l app=atlantis --tail=100

# Test Atlantis health endpoint
curl http://$ATLANTIS_URL/healthz

# Check Atlantis configuration
kubectl describe configmap atlantis -n atlantis
```

## 🔧 Operations & Maintenance

### Monitoring Atlantis

#### Application Logs

```console
# Follow Atlantis logs in real-time
kubectl logs -n atlantis -l app=atlantis --tail=50 -f

# Get logs from specific time range
kubectl logs -n atlantis -l app=atlantis --since=1h

# Export logs to file
kubectl logs -n atlantis -l app=atlantis > atlantis-logs.txt
```

#### Resource Monitoring

```console
# Check pod resource usage
kubectl top pods -n atlantis

# Check node resource usage
kubectl top nodes

# Describe Atlantis pod for detailed info
kubectl describe pod -n atlantis -l app=atlantis
```

### Scaling and Updates

#### Scale EKS Node Group

```console
# Update desired capacity in terraform.tfvars
desired_size = 2
max_size     = 3

# Apply the change
terraform apply -var-file=terraform.tfvars
```

#### Update Atlantis

```console
# Update Helm repository
helm repo update

# Check for new Atlantis versions
helm search repo atlantis

# Upgrade Atlantis
helm upgrade atlantis runatlantis/atlantis \
  --namespace atlantis \
  --reuse-values
```

### Backup and Recovery

#### Backup Terraform State

```console
# Download current state
aws s3 cp s3://your-terraform-state-bucket/dev/terraform-dev-state/dev.tfstate ./backup-$(date +%Y%m%d).tfstate

# List state backups
aws s3 ls s3://your-terraform-state-bucket/dev/terraform-dev-state/ --recursive
```

#### Backup Atlantis Data

```console
# Create backup of Atlantis PVC
kubectl get pvc -n atlantis

# Create a backup job (example)
kubectl create job atlantis-backup \
  --image=busybox \
  --dry-run=client -o yaml > backup-job.yaml
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Atlantis Pod Crashes

**Symptoms:**
- Pod in `CrashLoopBackOff` state
- Errors in pod logs

**Diagnosis:**
```console
kubectl describe pod -n atlantis -l app=atlantis
kubectl logs -n atlantis -l app=atlantis --previous
```

**Common Solutions:**
```console
# Check secret exists and has correct data
kubectl get secret atlantis-github -n atlantis -o yaml

# Verify IAM role ARN is correct
kubectl describe serviceaccount atlantis -n atlantis

# Check resource limits
kubectl describe pod -n atlantis -l app=atlantis | grep -A 10 "Limits\|Requests"
```

#### Issue 2: LoadBalancer Not Getting External IP

**Symptoms:**
- Service stuck in `<pending>` state
- No external IP assigned

**Diagnosis:**
```console
kubectl describe service atlantis -n atlantis
kubectl get events -n atlantis
```

**Solutions:**
```console
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Verify subnet tags for load balancer
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"
```

#### Issue 3: GitHub Webhook Failures

**Symptoms:**
- Webhook deliveries failing
- Atlantis not responding to PR events

**Diagnosis:**
```console
# Check webhook deliveries in GitHub
# Navigate to Settings > Webhooks > Recent Deliveries

# Check Atlantis logs for webhook events
kubectl logs -n atlantis -l app=atlantis | grep webhook
```

**Solutions:**
```console
# Verify webhook URL is accessible
curl http://$ATLANTIS_URL/events

# Check webhook secret matches
kubectl get secret atlantis-github -n atlantis -o jsonpath='{.data.ATLANTIS_GH_WEBHOOK_SECRET}' | base64 -d

# Recreate webhook if necessary
# (Use GitHub UI to delete and recreate webhook)
```

#### Issue 4: Terraform Plan/Apply Failures

**Symptoms:**
- Terraform commands fail in Atlantis
- Permission denied errors

**Diagnosis:**
```console
# Check Atlantis logs during plan/apply
kubectl logs -n atlantis -l app=atlantis | grep terraform

# Verify IAM permissions
aws sts get-caller-identity
```

**Solutions:**
```console
# Check service account annotation
kubectl get serviceaccount atlantis -n atlantis -o yaml

# Verify IAM role trust policy
aws iam get-role --role-name atlantis-cluster-atlantis-role

# Test IAM permissions manually
aws eks describe-cluster --name atlantis-cluster
```

### Debug Commands

```console
# Get all resources in atlantis namespace
kubectl get all -n atlantis

# Check events in atlantis namespace
kubectl get events -n atlantis --sort-by='.lastTimestamp'

# Port forward to access Atlantis directly
kubectl port-forward -n atlantis service/atlantis 4141:80

# Execute commands in Atlantis pod
kubectl exec -it -n atlantis deployment/atlantis -- /bin/sh

# Check Terraform state
terraform state list
terraform show
```

### Performance Optimization

#### EKS Node Optimization

```console
# Check node capacity
kubectl describe nodes

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Optimize instance types in terraform.tfvars
instance_types = ["t3.medium", "t3.large"]
```

#### Atlantis Performance

```console
# Increase Atlantis resources
helm upgrade atlantis runatlantis/atlantis \
  --namespace atlantis \
  --set resources.requests.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.limits.memory=2Gi \
  --set resources.limits.cpu=1000m
```

## 🔒 Security Considerations

### IAM Security Best Practices

#### Principle of Least Privilege

- ✅ Use specific IAM policies instead of `*` permissions
- ✅ Regularly audit IAM role permissions
- ✅ Implement resource-based policies where possible

```console
# Audit current IAM policies
aws iam list-attached-role-policies --role-name atlantis-cluster-atlantis-role

# Review policy details
aws iam get-policy-version \
  --policy-arn arn:aws:iam::ACCOUNT:policy/atlantis-cluster-atlantis-policy \
  --version-id v1
```

#### Service Account Security

```console
# Verify IRSA configuration
kubectl describe serviceaccount atlantis -n atlantis

# Check pod service account token
kubectl exec -n atlantis deployment/atlantis -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

### Network Security

#### VPC Security

- ✅ Private subnets for EKS nodes
- ✅ NAT Gateways for outbound internet access
- ✅ Security groups with minimal required ports
- ✅ Network ACLs for additional layer of security

```console
# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Verify EKS cluster security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw eks_cluster_security_group_id)
```

#### Kubernetes Security

```console
# Enable network policies (example with Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Create network policy for Atlantis namespace
cat > atlantis-network-policy.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: atlantis-network-policy
  namespace: atlantis
spec:
  podSelector:
    matchLabels:
      app: atlantis
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []
    ports:
    - protocol: TCP
      port: 4141
  egress:
  - {}
EOF

kubectl apply -f atlantis-network-policy.yaml
```

### Secrets Management

#### GitHub Token Security

```console
# Rotate GitHub token regularly
# 1. Generate new token in GitHub
# 2. Update Kubernetes secret
kubectl patch secret atlantis-github -n atlantis \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/ATLANTIS_GH_TOKEN", "value": "'$(echo -n 'NEW_TOKEN' | base64)'"}]'

# 3. Restart Atlantis pod
kubectl rollout restart deployment atlantis -n atlantis
```

#### Webhook Secret Security

```console
# Generate strong webhook secret
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Update secret in Kubernetes
kubectl patch secret atlantis-github -n atlantis \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/ATLANTIS_GH_WEBHOOK_SECRET", "value": "'$(echo -n $WEBHOOK_SECRET | base64)'"}]'

# Update GitHub webhook with new secret
```

### Compliance and Auditing

#### Enable CloudTrail

```console
# Create CloudTrail for API auditing
aws cloudtrail create-trail \
  --name atlantis-audit-trail \
  --s3-bucket-name your-cloudtrail-bucket \
  --include-global-service-events \
  --is-multi-region-trail

# Start logging
aws cloudtrail start-logging --name atlantis-audit-trail
```

#### Kubernetes Audit Logging

```console
# Check if audit logging is enabled
kubectl get configmap -n kube-system

# View audit logs (if enabled)
kubectl logs -n kube-system kube-apiserver-* | grep audit
```


### Development Workflow

#### Setting Up Development Environment

```console
# Fork the repository
git clone https://github.com/your-username/orion-atlantis-eks-deployment.git
cd orion-atlantis-eks-deployment

# Create development branch
git checkout -b feature/your-feature-name

# Set up pre-commit hooks
pip install pre-commit
pre-commit install
```

#### Code Quality Standards

```console
# Terraform formatting
terraform fmt -recursive

# Terraform validation
terraform validate

# Security scanning with tfsec
tfsec .

# Documentation generation
terraform-docs markdown table --output-file README.md .
```

#### Testing Changes

```console
# Test in development environment
terraform plan -var-file=terraform.tfvars.dev

# Validate with different configurations
terraform plan -var instance_types='["t3.small"]'
terraform plan -var desired_size=2
```


## 📚 References

### Official Documentation

- [Atlantis Documentation](https://www.runatlantis.io/docs/)
- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

### AWS Best Practices

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/latest/userguide/)

### Terraform Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Terraform Security Best Practices](https://blog.gitguardian.com/terraform-security-best-practices/)

### Community Resources

- [Atlantis GitHub Repository](https://github.com/runatlantis/atlantis)
- [EKS Workshop](https://www.eksworkshop.com/)
- [Terraform Up & Running Book](https://www.terraformupandrunning.com/)

## 🏆 Advanced Topics

### Multi-Environment Setup

#### Environment Structure

```console
# Directory structure for multiple environments
environments/
├── dev/
│   ├── terraform.tfvars
│   └── backend.tf
├── staging/
│   ├── terraform.tfvars
│   └── backend.tf
└── prod/
    ├── terraform.tfvars
    └── backend.tf
```

#### Environment-Specific Configuration

```console
# environments/dev/terraform.tfvars
cluster_name = "atlantis-dev"
instance_types = ["t3.small"]
desired_size = 1

# environments/prod/terraform.tfvars
cluster_name = "atlantis-prod"
instance_types = ["t3.medium"]
desired_size = 2
min_size = 2
```


### Disaster Recovery

#### Backup Strategy

```console
# Backup EKS cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup persistent volumes
kubectl get pv -o yaml > pv-backup.yaml
kubectl get pvc --all-namespaces -o yaml > pvc-backup.yaml
```

#### Recovery Procedures

```bash
# Restore from Terraform state
terraform import module.eks.aws_eks_cluster.this atlantis-cluster

# Restore Kubernetes resources
kubectl apply -f cluster-backup.yaml
```

## 🎯 Quick Start Summary

For experienced users, here's a condensed quick start:

```console
# 1. Clone and configure
git clone https://github.com/Barsmiko1/orion-atlantis-eks-deployment.git
cd orion-atlantis-eks-deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Deploy infrastructure
terraform init
terraform apply -var-file=terraform.tfvars

# 3. Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name atlantis-cluster

# 4. Deploy Atlantis
kubectl create namespace atlantis
kubectl create secret generic atlantis-github \
  --namespace atlantis \
  --from-literal=ATLANTIS_GH_USER="$GH_USER" \
  --from-literal=ATLANTIS_GH_TOKEN="$GH_TOKEN" \
  --from-literal=ATLANTIS_GH_WEBHOOK_SECRET="$WEBHOOK_SECRET"

helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm install atlantis runatlantis/atlantis \
  --namespace atlantis \
  --set orgAllowlist="github.com/$GH_USER/*" \
  --set github.user="$GH_USER" \
  --set github.token="$GH_TOKEN" \
  --set github.secret="$WEBHOOK_SECRET" \
  --set service.type=LoadBalancer \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$(terraform output -raw atlantis_iam_role_arn)"

# 5. Configure GitHub webhook with Atlantis URL
kubectl get service atlantis -n atlantis
```

## 📋 Checklist

### Pre-Deployment Checklist

- [ ] AWS CLI configured with appropriate permissions
- [ ] Terraform, kubectl, and Helm installed
- [ ] GitHub personal access token generated
- [ ] S3 bucket created for Terraform state
- [ ] terraform.tfvars configured with your values
- [ ] Backend configuration updated

### Post-Deployment Checklist

- [ ] Infrastructure deployed successfully
- [ ] EKS cluster accessible via kubectl
- [ ] Atlantis pod running and healthy
- [ ] LoadBalancer has external IP assigned
- [ ] GitHub webhook configured and tested
- [ ] Sample pull request workflow tested
- [ ] Monitoring and logging configured
- [ ] Security policies reviewed and applied
- [ ] Cost optimization measures implemented
- [ ] Documentation updated with environment-specific details

---


**Happy Infrastructure Automating!** 🚀

*Remember: Infrastructure as Code + Pull Request Workflows = DevOps Heaven* 


