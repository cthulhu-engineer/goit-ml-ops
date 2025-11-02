# AWS EKS Deployment Guide

## Prerequisites

1. AWS CLI installed and configured
2. Terraform installed
3. kubectl installed
4. Helm installed

## Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter region: us-east-1
# Enter output format: json
```

## Step 2: Create EKS Cluster with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Create cluster (takes ~15-20 minutes)
terraform apply -auto-approve
```

## Step 3: Configure kubectl

```bash
# Get the kubeconfig command from terraform output
aws eks update-kubeconfig --region us-east-1 --name sensor-quality-cluster

# Verify connection
kubectl get nodes
```

## Step 4: Install Full Stack

```bash
# Make script executable
chmod +x terraform/install-stack.sh

# Run installation
./terraform/install-stack.sh
```

Wait for all LoadBalancers to get external IPs (~5-10 minutes).

## Step 5: Get Service URLs

```bash
# ArgoCD
echo "ArgoCD URL: http://$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Grafana
echo "Grafana URL: http://$(kubectl get svc kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "Username: admin"
echo "Password: admin"

# Prometheus
echo "Prometheus URL: http://$(kubectl get svc kube-prometheus-stack-prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9090"

# MLflow
echo "MLflow URL: http://$(kubectl get svc mlflow -n mlflow -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):5000"
```

## Step 6: Build and Push Docker Image

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u cthulhu-engineer --password-stdin

# Build image
docker build -t ghcr.io/cthulhu-engineer/goit-ml-ops/sensor-quality-inference:latest .

# Push image
docker push ghcr.io/cthulhu-engineer/goit-ml-ops/sensor-quality-inference:latest
```

## Step 7: Deploy Application via ArgoCD

```bash
# Login to ArgoCD CLI
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure

# Create application
kubectl apply -f argocd/sensor-quality-inference.yaml

# Or via CLI
argocd app create sensor-quality-inference \
  --repo https://github.com/cthulhu-engineer/goit-ml-ops.git \
  --path helm \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace sensor-quality \
  --revision final-project \
  --sync-policy automated

# Sync application
argocd app sync sensor-quality-inference
```

## Step 8: Configure Loki in Grafana

1. Open Grafana URL
2. Go to Configuration → Data Sources
3. Add Loki: `http://loki.logging.svc.cluster.local:3100`
4. Import dashboard from `grafana/sensor-quality-dashboard.json`

## Step 9: Access Application

```bash
# Get application URL
kubectl get svc -n sensor-quality

# If using LoadBalancer:
echo "App URL: http://$(kubectl get svc sensor-quality-inference -n sensor-quality -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8000"
```

## Screenshots to Take

1. **ArgoCD UI**: Show deployed application
2. **Prometheus**: Show metrics being scraped
3. **Grafana**: Show Loki logs dashboard
4. **MLflow**: Show experiment runs
5. **Swagger UI**: `/docs` - Test anomaly detection
6. **GitHub Actions**: Show CI/CD pipeline running

## Cleanup

```bash
# Delete ArgoCD app
argocd app delete sensor-quality-inference

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

## Estimated Costs

- EKS Cluster: ~$0.10/hour ($73/month)
- EC2 instances (2x t3.medium): ~$0.08/hour ($60/month)
- Load Balancers (4): ~$0.025/hour each ($72/month)
- EBS volumes: ~$0.10/GB-month

**Total: ~$205/month** (or ~$0.28/hour for testing)

**For demo/testing**: Run for 2-3 hours = ~$1-2 total cost
