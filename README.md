# AWS EKS Cluster with VPC - Production-Ready Terraform Configuration

![Terraform](https://img.shields.io/badge/Terraform-1.0%2B-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.27--1.31-326CE5?logo=kubernetes)

Цей проєкт надає production-ready Terraform конфігурацію для розгортання повноцінної інфраструктури AWS EKS (Elastic Kubernetes Service) з відокремленими node group-ами для CPU та GPU навантажень.

## Архітектура

### Компоненти інфраструктури

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Account                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                        VPC (10.0.0.0/16)                  │   │
│  │  ┌─────────────┬─────────────┬─────────────┐             │   │
│  │  │   AZ-1a     │   AZ-1b     │   AZ-1c     │             │   │
│  │  ├─────────────┼─────────────┼─────────────┤             │   │
│  │  │ Public      │ Public      │ Public      │             │   │
│  │  │ Subnet      │ Subnet      │ Subnet      │             │   │
│  │  │ 10.0.1.0/24 │ 10.0.2.0/24 │ 10.0.3.0/24 │             │   │
│  │  │             │             │             │             │   │
│  │  │  NAT-GW     │  NAT-GW     │  NAT-GW     │  ◄── High   │   │
│  │  │             │             │             │      Avail. │   │
│  │  ├─────────────┼─────────────┼─────────────┤             │   │
│  │  │ Private     │ Private     │ Private     │             │   │
│  │  │ Subnet      │ Subnet      │ Subnet      │             │   │
│  │  │ 10.0.101/24 │ 10.0.102/24 │ 10.0.103/24 │             │   │
│  │  │             │             │             │             │   │
│  │  │ ┌─────────┐ │ ┌─────────┐ │ ┌─────────┐ │             │   │
│  │  │ │EKS Nodes│ │ │EKS Nodes│ │ │EKS Nodes│ │             │   │
│  │  │ │ (CPU)   │ │ │ (CPU)   │ │ │ (GPU)   │ │             │   │
│  │  │ └─────────┘ │ └─────────┘ │ └─────────┘ │             │   │
│  │  │             │             │             │             │   │
│  │  ├─────────────┼─────────────┼─────────────┤             │   │
│  │  │ Database    │ Database    │ Database    │             │   │
│  │  │ Subnet      │ Subnet      │ Subnet      │             │   │
│  │  │ 10.0.201/24 │ 10.0.202/24 │ 10.0.203/24 │             │   │
│  │  └─────────────┴─────────────┴─────────────┘             │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────┐           │   │
│  │  │         EKS Control Plane                  │           │   │
│  │  │  - Kubernetes API Server                   │           │   │
│  │  │  - etcd                                    │           │   │
│  │  │  - Scheduler                               │           │   │
│  │  │  - Controller Manager                      │           │   │
│  │  └────────────────────────────────────────────┘           │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Ключові features

#### VPC Module
- ✅ **High Availability**: 3 Availability Zones з окремими NAT Gateways
- ✅ **Network Segmentation**: Публічні, приватні та database subnet-и
- ✅ **VPC Flow Logs**: Моніторинг мережевого трафіку
- ✅ **EKS Integration Tags**: Автоматичне виявлення subnet-ів для Load Balancers

#### EKS Module
- ✅ **Managed Node Groups**: Окремі групи для CPU та GPU навантажень
- ✅ **GPU Support**: Правильні instance types (g4dn.xlarge) з NVIDIA GPU
- ✅ **Node Labels & Taints**: Автоматичне розподілення workload-ів
- ✅ **Security**: KMS encryption для secrets, IMDSv2, security groups
- ✅ **Logging**: Control plane logging (API, audit, authenticator)
- ✅ **Add-ons**: CoreDNS, kube-proxy, VPC CNI, EBS CSI Driver
- ✅ **IRSA Support**: OIDC provider для IAM Roles for Service Accounts

## Prerequisites

### Інструменти
```bash
# Terraform >= 1.0
terraform --version

# AWS CLI >= 2.0
aws --version

# kubectl >= 1.27
kubectl version --client

# Optional: eksctl для додаткового управління
eksctl version
```

### AWS Credentials

1. **Налаштування AWS Profile**:
```bash
aws configure --profile default
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json
```

2. **Необхідні IAM Permissions**:
Ваш IAM користувач або роль повинні мати права на:
- EC2 (VPC, Subnets, NAT Gateways, Security Groups)
- EKS (Cluster creation, Node groups)
- IAM (Roles, Policies для EKS)
- CloudWatch Logs (для VPC Flow Logs та EKS logging)
- S3 (якщо використовуєте S3 backend)
- DynamoDB (якщо використовуєте state locking)

Рекомендована managed policy: `AdministratorAccess` (для development) або custom policy з мінімальними правами для production.

## Швидкий старт

### 1. Клонування та налаштування

```bash
# Клонуйте репозиторій
git clone <repository-url>
cd MLops-Lesson-5-6

# Створіть terraform.tfvars з terraform.tfvars.example
cp terraform.tfvars.example terraform.tfvars

# Відредагуйте terraform.tfvars згідно з вашими потребами
nano terraform.tfvars
```

### 2. Налаштування змінних

Відредагуйте `terraform.tfvars`:

```hcl
# Базова конфігурація
region      = "us-east-1"
aws_profile = "default"

# VPC
vpc_name           = "my-eks-vpc"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS
cluster_name    = "my-eks-cluster"
cluster_version = "1.31"

# CPU Nodes
cpu_instance_types   = ["t3.medium"]
cpu_desired_capacity = 2
cpu_min_capacity     = 1
cpu_max_capacity     = 4

# GPU Nodes (встановіть desired=0 щоб заощадити кошти)
gpu_instance_types   = ["g4dn.xlarge"]
gpu_desired_capacity = 0
gpu_min_capacity     = 0
gpu_max_capacity     = 2

# Теги
tags = {
  Environment = "development"
  Project     = "my-project"
  Owner       = "devops-team"
}
```

### 3. Deployment

```bash
# Ініціалізація Terraform
terraform init

# Перегляд плану змін
terraform plan

# Застосування конфігурації (створення інфраструктури)
terraform apply

# Підтвердження: введіть 'yes'
```

Deployment займе **~15-20 хвилин**.

### 4. Підключення до кластера

Після успішного deployment:

```bash
# Налаштування kubectl
aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster

# Перевірка підключення
kubectl get nodes

# Приклад виводу:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-101-xx.ec2.internal   Ready    <none>   5m    v1.31.0-eks-xxx
# ip-10-0-102-xx.ec2.internal   Ready    <none>   5m    v1.31.0-eks-xxx
```

## Структура проєкту

```
.
├── README.md                    # Ця документація
├── main.tf                      # Root конфігурація, виклик модулів
├── variables.tf                 # Оголошення змінних
├── outputs.tf                   # Outputs проєкту
├── locals.tf                    # Local values, обчислені значення
├── data.tf                      # Data sources
├── terraform.tf                 # Provider requirements
├── backend.tf                   # Backend конфігурація
├── terraform.tfvars.example     # Приклад значень змінних
├── .gitignore                   # Git ignore rules
│
├── vpc/                         # VPC модуль
│   ├── main.tf                  # VPC ресурси
│   ├── variables.tf             # VPC змінні
│   ├── outputs.tf               # VPC outputs
│   ├── terraform.tf             # Provider configuration
│   └── backend.tf               # Backend placeholder
│
└── eks/                         # EKS модуль
    ├── main.tf                  # EKS cluster та node groups
    ├── variables.tf             # EKS змінні
    ├── outputs.tf               # EKS outputs
    ├── terraform.tf             # Provider configuration
    └── backend.tf               # Backend placeholder
```

## Node Groups

### CPU Node Group

**Призначення**: Загальні workload-и, веб-сервіси, API

**Характеристики**:
- Instance Type: `t3.medium` (2 vCPU, 4 GB RAM)
- AMI: Amazon Linux 2
- Disk: 50 GB gp3 (encrypted)
- Labels: `workload-type=cpu`, `node-type=standard`
- Taints: Немає (приймає всі pod-и)

**Приклад deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  template:
    spec:
      # Автоматично розподілиться на CPU nodes
      containers:
      - name: nginx
        image: nginx:latest
```

### GPU Node Group

**Призначення**: ML/AI workload-и, навчання моделей, inference

**Характеристики**:
- Instance Type: `g4dn.xlarge` (4 vCPU, 16 GB RAM, NVIDIA T4 GPU)
- AMI: Amazon Linux 2 GPU-optimized
- Disk: 100 GB gp3 (encrypted)
- Labels: `workload-type=gpu`, `nvidia.com/gpu=true`
- Taints: `nvidia.com/gpu=true:NoSchedule` (тільки GPU workload-и)

**Приклад deployment з GPU**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-training
spec:
  template:
    spec:
      # Toleration для GPU taint
      tolerations:
      - key: nvidia.com/gpu
        operator: Equal
        value: "true"
        effect: NoSchedule

      # Node selector для GPU nodes
      nodeSelector:
        workload-type: gpu

      containers:
      - name: pytorch
        image: pytorch/pytorch:latest
        resources:
          limits:
            nvidia.com/gpu: 1  # Request 1 GPU
```

## Безпека

### Network Security

1. **Private EKS Nodes**: Всі worker node-и в приватних subnet-ах
2. **NAT Gateways**: По одному в кожній AZ для високої доступності
3. **Security Groups**: Автоматично налаштовані EKS security groups
4. **VPC Flow Logs**: Моніторинг всього мережевого трафіку

### Kubernetes Security

1. **RBAC**: AWS IAM інтегрований з Kubernetes RBAC
2. **IRSA**: IAM Roles for Service Accounts через OIDC
3. **Secrets Encryption**: KMS encryption для Kubernetes secrets (опціонально)
4. **Network Policies**: Підтримується через Calico або AWS VPC CNI

### Best Practices

```hcl
# У production обов'язково змініть:
cluster_public_access_cidrs = ["YOUR_OFFICE_IP/32"]  # Не 0.0.0.0/0!

# Увімкніть KMS encryption
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/..."

# Максимальне логування для production
cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

## Моніторинг та Logging

### CloudWatch Logs

Кластер автоматично надсилає логи в CloudWatch:
- API Server logs
- Audit logs
- Authenticator logs

```bash
# Перегляд логів через AWS CLI
aws logs tail /aws/eks/my-eks-cluster/cluster --follow
```

### Container Insights (Опціонально)

```bash
# Встановлення CloudWatch Container Insights
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml
```

### Prometheus & Grafana (Опціонально)

```bash
# Встановлення через Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

## Cost Optimization

### Приблизна вартість (на місяць)

| Компонент | Конфігурація | Вартість (USD) |
|-----------|--------------|----------------|
| EKS Control Plane | 1 cluster | $73 |
| VPC NAT Gateways | 3x NAT-GW | $97 |
| CPU Nodes | 2x t3.medium | $60 |
| GPU Nodes | 0x g4dn.xlarge | $0 |
| VPC Flow Logs | 7 days retention | $5 |
| **Total** | | **~$235/month** |

GPU Node (якщо запущено):
- 1x g4dn.xlarge = **$526/month**

### Поради по економії

1. **GPU Nodes**: Встановіть `desired_capacity = 0` коли не використовуються
```bash
# Масштабування GPU nodes до 0
terraform apply -var="gpu_desired_capacity=0"
```

2. **Spot Instances**: Використовуйте для non-critical workload-ів
```hcl
# У eks/main.tf додайте
capacity_type = "SPOT"
```

3. **Cluster Autoscaler**: Автоматичне масштабування
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

4. **Налаштування scheduling**:
```bash
# Вимкнення кластера на ніч (development)
# Через AWS Lambda або scheduled task
aws eks update-nodegroup-config --cluster-name my-eks-cluster \
  --nodegroup-name cpu-nodes --scaling-config minSize=0,maxSize=4,desiredSize=0
```

## Troubleshooting

### Проблема: Nodes не з'являються

```bash
# 1. Перевірте node groups
aws eks list-nodegroups --cluster-name my-eks-cluster

# 2. Перевірте статус node group
aws eks describe-nodegroup --cluster-name my-eks-cluster \
  --nodegroup-name my-eks-cluster-cpu-nodes

# 3. Перевірте CloudWatch Logs
aws logs tail /aws/eks/my-eks-cluster/cluster --follow
```

### Проблема: Permission denied

```bash
# Оновіть kubeconfig
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1

# Перевірте IAM mapping
kubectl describe configmap -n kube-system aws-auth
```

### Проблема: GPU не виявляється

```bash
# 1. Перевірте NVIDIA device plugin
kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset

# 2. Якщо немає, встановіть
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/master/nvidia-device-plugin.yml

# 3. Перевірте GPU на node
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable."nvidia\.com/gpu"
```

## Оновлення кластера

### Kubernetes Version Upgrade

```bash
# 1. Оновіть версію у terraform.tfvars
cluster_version = "1.32"

# 2. Застосуйте зміни
terraform plan
terraform apply

# 3. Оновіть add-ons (автоматично через Terraform)
# 4. Перевірте статус
kubectl version --short
```

### Add-ons Update

Add-ons оновлюються автоматично з `most_recent = true`.

## Видалення інфраструктури

### ВАЖЛИВО: Попередження про витрати

```bash
# Перед видаленням:
# 1. Видаліть всі LoadBalancer services (щоб AWS видалив ELB)
kubectl delete svc --all --all-namespaces

# 2. Видаліть всі PersistentVolumeClaims (щоб AWS видалив EBS)
kubectl delete pvc --all --all-namespaces

# 3. Зачекайте 2-3 хвилини для завершення видалення

# 4. Запустіть terraform destroy
terraform destroy

# Підтвердіть: yes
```

### Порядок видалення

Terraform автоматично видалить ресурси в правильному порядку:
1. EKS Node Groups
2. EKS Cluster
3. NAT Gateways
4. Subnets
5. VPC

**Час видалення**: ~10-15 хвилин

## Advanced Usage

### Multi-Environment Setup

```bash
# Використовуйте Terraform Workspaces
terraform workspace new production
terraform workspace new staging

# Deploy для staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

# Deploy для production
terraform workspace select production
terraform apply -var-file="production.tfvars"
```

### IRSA (IAM Roles for Service Accounts)

```hcl
# Створіть IAM роль для pod
module "iam_role_for_service_account" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "my-app-role"

  oidc_providers = {
    main = {
      provider_arn = module.eks.eks_oidc_provider_arn
      namespace_service_accounts = ["default:my-app"]
    }
  }

  role_policy_arns = {
    s3 = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }
}
```

## Подяки та ліцензія

Базується на офіційних AWS Terraform модулях:
- [terraform-aws-modules/vpc/aws](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [terraform-aws-modules/eks/aws](https://github.com/terraform-aws-modules/terraform-aws-eks)

Створено в рамках курсу MLOps.

---

**Підтримка**: Для питань та issues створіть issue в репозиторії.

**Версія**: 1.0.0
**Останнє оновлення**: 2025
