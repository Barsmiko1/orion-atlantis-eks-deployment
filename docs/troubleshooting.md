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
