# IoT Sensor Quality Monitoring - MLOps Project

Production-ready MLOps infrastructure for IoT sensor anomaly detection with AWS EKS, ArgoCD, Prometheus, and Grafana.

## Architecture

- **FastAPI**: REST API for real-time anomaly detection
- **Isolation Forest**: ML model for anomaly detection
- **Kubernetes (EKS)**: Container orchestration
- **ArgoCD**: GitOps continuous deployment
- **Prometheus + Grafana**: Metrics and visualization
- **Loki + Promtail**: Log aggregation
- **MLflow**: Experiment tracking
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD pipeline

## Quick Start

### 1. Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Train model
python model/train_iot_sensors.py

# Run API
uvicorn app.main:app --reload

# Test API
curl -X POST "http://localhost:8000/detect" \
  -H "Content-Type: application/json" \
  -d '{"temperature": 23, "humidity": 55, "pressure": 1013, "vibration": 0.8, "hour_of_day": 14}'
```

### 2. AWS EKS Deployment

See [AWS_SETUP.md](AWS_SETUP.md) for complete instructions.

```bash
# Deploy infrastructure
cd terraform
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name sensor-quality-cluster

# Install stack
./terraform/install-stack.sh

# Deploy application
kubectl apply -f argocd/sensor-quality-inference.yaml
```

## API Endpoints

- `GET /` - Service info
- `GET /health` - Health check
- `POST /detect` - Anomaly detection
- `GET /metrics` - Prometheus metrics
- `GET /stats` - Service statistics
- `GET /docs` - Swagger UI

## Monitoring

- **Grafana**: http://[GRAFANA_URL] (admin/admin)
- **Prometheus**: http://[PROMETHEUS_URL]:9090
- **ArgoCD**: http://[ARGOCD_URL]
- **MLflow**: http://[MLFLOW_URL]:5000

## Model Training

Model uses Isolation Forest algorithm with these features:
- Temperature (°C)
- Humidity (%)
- Pressure (hPa)
- Vibration (g)
- Hour of day (0-23)

## Project Structure

```
.
├── app/                    # FastAPI application
│   └── main.py
├── model/                  # ML model training
│   └── train_iot_sensors.py
├── helm/                   # Kubernetes Helm charts
├── argocd/                 # ArgoCD configurations
├── terraform/              # AWS infrastructure
├── .github/workflows/      # CI/CD pipelines
├── prometheus/             # Prometheus configs
├── grafana/                # Grafana dashboards
├── Dockerfile             # Container image
└── requirements.txt       # Python dependencies
```

## License

MIT
