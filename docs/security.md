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
