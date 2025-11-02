#!/bin/bash
set -e

echo "🚀 Installing full MLOps stack on EKS cluster..."

# 1. Create namespaces
echo "📦 Creating namespaces..."
kubectl create namespace sensor-quality || true
kubectl create namespace argocd || true
kubectl create namespace monitoring || true
kubectl create namespace logging || true
kubectl create namespace mlflow || true

# 2. Install ArgoCD
echo "🔄 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Expose ArgoCD server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get ArgoCD admin password
echo "🔑 ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# 3. Install Prometheus + Grafana
echo "📊 Installing Prometheus + Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin

# Expose Grafana
kubectl patch svc kube-prometheus-stack-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

# Expose Prometheus
kubectl patch svc kube-prometheus-stack-prometheus -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

# 4. Install Loki + Promtail
echo "📝 Installing Loki + Promtail..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace logging \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi

# 5. Install MLflow
echo "🔬 Installing MLflow..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mlflow-pvc
  namespace: mlflow
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow
  namespace: mlflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mlflow
  template:
    metadata:
      labels:
        app: mlflow
    spec:
      containers:
      - name: mlflow
        image: ghcr.io/mlflow/mlflow:v2.18.0
        ports:
        - containerPort: 5000
        command:
          - mlflow
          - server
          - --host
          - "0.0.0.0"
          - --port
          - "5000"
          - --backend-store-uri
          - /mlflow
          - --default-artifact-root
          - /mlflow/artifacts
        volumeMounts:
        - name: mlflow-storage
          mountPath: /mlflow
      volumes:
      - name: mlflow-storage
        persistentVolumeClaim:
          claimName: mlflow-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mlflow
  namespace: mlflow
spec:
  type: LoadBalancer
  selector:
    app: mlflow
  ports:
  - port: 5000
    targetPort: 5000
EOF

echo "✅ Installation complete!"
echo ""
echo "🌐 Getting service URLs..."
echo ""
echo "ArgoCD:"
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo "Grafana:"
kubectl get svc kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo "Prometheus:"
kubectl get svc kube-prometheus-stack-prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo "MLflow:"
kubectl get svc mlflow -n mlflow -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
