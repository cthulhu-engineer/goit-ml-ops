# MLOps Infrastructure Platform

Навчальний проєкт для демонстрації розгортання повноцінної MLOps інфраструктури на базі Kubernetes. Проєкт включає GitOps підхід з ArgoCD та платформу для управління ML експериментами MLflow.

## Що це за проєкт?

Це практичний приклад організації інфраструктури для Machine Learning Operations (MLOps), який демонструє:

- Автоматизоване розгортання компонентів через GitOps (ArgoCD)
- Управління інфраструктурою як кодом (Terraform)
- Оркестрацію контейнерів через Kubernetes
- Платформу для трекінгу ML експериментів (MLflow)
- Можливість локальної розробки та тестування

Проєкт орієнтований на тих, хто вивчає MLOps практики та хоче отримати hands-on досвід роботи з сучасним стеком технологій.

## Архітектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                         (Minikube)                           │
│                                                              │
│  ┌──────────────────────────┐  ┌─────────────────────────┐ │
│  │   Namespace: infra-tools │  │   Namespace: mlflow     │ │
│  │                          │  │                         │ │
│  │  ┌──────────────────┐    │  │  ┌──────────────────┐  │ │
│  │  │                  │    │  │  │                  │  │ │
│  │  │     ArgoCD       │────┼──┼─▶│   MLflow Server  │  │ │
│  │  │   (GitOps Tool)  │    │  │  │  (ML Platform)   │  │ │
│  │  │                  │    │  │  │                  │  │ │
│  │  └──────────────────┘    │  │  └──────────────────┘  │ │
│  │          │               │  │          │             │ │
│  │          │               │  │          │             │ │
│  │   [Port: 8080]           │  │   [Port: 5000]         │ │
│  └──────────────────────────┘  └─────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │
                    ┌──────┴──────┐
                    │   Terraform │
                    │     (IaC)   │
                    └─────────────┘
                           ▲
                           │
                    ┌──────┴──────┐
                    │  Git Repo   │
                    │   (GitHub)  │
                    └─────────────┘
```

### Компоненти системи

#### 1. Kubernetes (Minikube)
Локальний Kubernetes кластер для розробки та тестування. Minikube дозволяє запустити повноцінний Kubernetes кластер на локальній машині.

#### 2. ArgoCD
GitOps контролер, який автоматично розгортає та синхронізує стан додатків у Kubernetes відповідно до конфігурацій у Git репозиторії.

**Основні можливості:**
- Автоматична синхронізація з Git репозиторієм
- Web UI для моніторингу стану додатків
- Декларативне управління конфігураціями
- Rollback до попередніх версій

#### 3. MLflow
Платформа для управління повним життєвим циклом ML моделей.

**Основні можливості:**
- Трекінг експериментів (метрики, параметри)
- Збереження артефактів моделей
- Управління версіями моделей
- Model Registry

#### 4. Terraform
Infrastructure as Code інструмент для декларативного опису та управління інфраструктурою.

## Передумови

Перед початком роботи переконайтесь, що у вас встановлені наступні інструменти:

### Обов'язкові інструменти

| Інструмент | Версія | Призначення | Посилання |
|------------|--------|-------------|-----------|
| **Docker Desktop** | 20.10+ | Контейнеризація та Kubernetes | [Download](https://www.docker.com/products/docker-desktop/) |
| **Minikube** | 1.30+ | Локальний Kubernetes кластер | [Install Guide](https://minikube.sigs.k8s.io/docs/start/) |
| **kubectl** | 1.27+ | CLI для управління Kubernetes | [Install Guide](https://kubernetes.io/docs/tasks/tools/) |
| **Terraform** | 1.0+ | Infrastructure as Code | [Install Guide](https://developer.hashicorp.com/terraform/downloads) |
| **Git** | 2.30+ | Контроль версій | [Download](https://git-scm.com/downloads) |

### Системні вимоги

- **CPU:** Мінімум 2 cores (рекомендовано 4+)
- **RAM:** Мінімум 4 GB (рекомендовано 8 GB+)
- **Disk:** Мінімум 20 GB вільного місця
- **OS:** macOS, Linux, або Windows 10/11 з WSL2

### Перевірка встановлення

Після встановлення всіх інструментів перевірте їх версії:

```bash
# Docker
docker --version
# Приклад виводу: Docker version 24.0.5, build ced0996

# Minikube
minikube version
# Приклад виводу: minikube version: v1.31.2

# kubectl
kubectl version --client
# Приклад виводу: Client Version: v1.28.0

# Terraform
terraform --version
# Приклад виводу: Terraform v1.5.7

# Git
git --version
# Приклад виводу: git version 2.39.2
```

## Швидкий старт

Цей розділ допоможе вам розгорнути повну інфраструктуру на локальній машині за 10-15 хвилин.

### Крок 1: Клонування репозиторію

```bash
# Клонуємо проєкт
git clone https://github.com/cthulhu-engineer/goit-ml-ops.git
cd goit-ml-ops

# Переключаємось на гілку lesson-7
git checkout lesson-7
```

### Крок 2: Запуск локального Kubernetes кластера

```bash
# Запускаємо Minikube з необхідними ресурсами
minikube start --cpus=2 --memory=4096 --driver=docker

# Перевіряємо статус кластера
minikube status
```

**Пояснення:**
- `--cpus=2` - виділяємо 2 CPU cores для кластера
- `--memory=4096` - виділяємо 4 GB RAM
- `--driver=docker` - використовуємо Docker як драйвер віртуалізації

**Очікуваний результат:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Крок 3: Розгортання ArgoCD

ArgoCD - це GitOps контролер, який буде автоматично розгортати наші додатки.

```bash
# Переходимо в директорію з конфігурацією ArgoCD для локального кластера
cd argocd-local

# Ініціалізуємо Terraform
terraform init

# Переглядаємо план розгортання
terraform plan

# Застосовуємо конфігурацію
terraform apply
```

**Що відбувається під капотом:**
1. Terraform створює namespace `infra-tools` у Kubernetes
2. Встановлюється ArgoCD через Helm chart (версія 2.8.4)
3. Конфігуруються ресурси для оптимальної роботи на локальній машині
4. Налаштовуються RBAC правила та сервіси

**Час розгортання:** ~2-3 хвилини

Terraform запитає підтвердження. Введіть `yes` та натисніть Enter.

**Очікуваний результат:**
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

argocd_access_info = <<EOT

ArgoCD успішно розгорнуто!
...
EOT
```

### Крок 4: Доступ до ArgoCD UI

Після успішного розгортання отримаємо пароль адміністратора:

```bash
# Отримуємо пароль (збережіть його!)
kubectl get secret argocd-initial-admin-secret \
  -n infra-tools \
  -o jsonpath="{.data.password}" | base64 --decode && echo
```

**Важливо:** Збережіть цей пароль у безпечному місці. Він буде потрібен для входу в ArgoCD UI.

Налаштовуємо доступ до веб-інтерфейсу:

```bash
# Запускаємо port forwarding (залиште цей термінал відкритим)
kubectl port-forward svc/argocd-server -n infra-tools 8080:80
```

Відкрийте браузер та перейдіть на: **http://localhost:8080**

**Credentials:**
- **Username:** `admin`
- **Password:** пароль, отриманий на попередньому кроці

### Крок 5: Розгортання MLflow

Повернемось в кореневу директорію проєкту:

```bash
# Повертаємось назад (якщо ви все ще в argocd-local/)
cd ..
```

Тепер розгорнемо MLflow двома способами:

#### Варіант A: Через GitOps (рекомендовано для production)

```bash
# Розгортаємо ArgoCD Application, яка автоматично створить MLflow
kubectl apply -f applications/mlflow-local.yaml

# Перевіряємо статус синхронізації в ArgoCD UI
# Або через CLI:
kubectl get applications -n infra-tools
```

#### Варіант B: Безпосередньо через kubectl (для швидкого тестування)

```bash
# Застосовуємо Kubernetes маніфести
kubectl apply -f applications/mlflow-standalone.yaml

# Перевіряємо статус розгортання
kubectl get all -n mlflow

# Очікуємо поки pod стане Ready
kubectl wait --for=condition=ready pod -l app=mlflow -n mlflow --timeout=120s
```

**Очікуваний результат:**
```
namespace/mlflow created
deployment.apps/mlflow-server created
service/mlflow-service created
pod/mlflow-server-xxxxx condition met
```

### Крок 6: Доступ до MLflow UI

MLflow UI дозволяє переглядати експерименти, метрики, параметри та артефакти моделей.

#### Для Minikube (рекомендований спосіб):

```bash
# Minikube автоматично створить тунель та відкриє браузер
minikube service mlflow-service -n mlflow
```

**Що відбувається:** Minikube створює NodePort та відкриває браузер з правильним URL (наприклад, http://127.0.0.1:55432)

#### Альтернативний спосіб (port-forward):

```bash
# Запускаємо port forwarding (в новому терміналі)
kubectl port-forward -n mlflow svc/mlflow-service 5000:5000
```

Відкрийте браузер: **http://localhost:5000**

### Крок 7: Перевірка роботи системи

Переконайтесь, що всі компоненти працюють коректно:

```bash
# Статус усіх pods
kubectl get pods --all-namespaces

# Статус сервісів
kubectl get services --all-namespaces

# Детальна інформація про MLflow
kubectl describe deployment mlflow-server -n mlflow
```

**Всі pods повинні мати статус `Running` або `Completed`.**

## Структура проєкту

```
.
├── README.md                       # Ця документація
├── .gitignore                      # Git ignore rules
│
├── argocd/                         # ArgoCD для AWS EKS (production)
│   ├── main.tf                     # Helm release конфігурація
│   ├── variables.tf                # Terraform змінні (region, cluster, etc.)
│   ├── terraform.tf                # Provider конфігурація (AWS, K8s, Helm)
│   ├── backend.tf                  # S3 backend для state
│   ├── outputs.tf                  # Outputs (URL, інструкції)
│   └── values/
│       └── argocd-values.yaml      # Helm values для ArgoCD
│
├── argocd-local/                   # ArgoCD для локального Minikube
│   ├── main.tf                     # Спрощена конфігурація для локального кластера
│   ├── variables.tf                # Змінні (namespace, release_name)
│   └── outputs.tf                  # Інструкції доступу
│
├── applications/                   # Kubernetes маніфести для додатків
│   ├── application.yaml            # ArgoCD Application для AWS (GitOps)
│   ├── mlflow-local.yaml           # ArgoCD Application для Minikube (GitOps)
│   └── mlflow-standalone.yaml      # Standalone MLflow (без GitOps)
│
└── eks/                           # AWS EKS кластер (опціонально для production)
    ├── main.tf                     # VPC + EKS module конфігурація
    ├── variables.tf                # EKS змінні (node_type, cluster_version)
    └── terraform.tf                # AWS provider + S3 backend
```

### Опис основних директорій

#### `argocd/` та `argocd-local/`
Terraform модулі для розгортання ArgoCD. `argocd-local/` оптимізований для роботи на локальній машині з мінімальними ресурсами, тоді як `argocd/` призначений для production AWS EKS кластера.

#### `applications/`
Kubernetes маніфести, які описують додатки для розгортання:
- **application.yaml** - ArgoCD Application для AWS
- **mlflow-local.yaml** - ArgoCD Application для Minikube з GitOps
- **mlflow-standalone.yaml** - прямі Kubernetes ресурси для швидкого тестування

#### `eks/`
Terraform конфігурація для створення AWS EKS кластера. Опціональна для локальної розробки, необхідна для production deployment.

## Конфігурація компонентів

### ArgoCD

**Версія:** v2.8.4
**Namespace:** infra-tools
**Helm Chart:** argo/argo-cd v5.46.8

**Основні налаштування:**
```yaml
server:
  service:
    type: ClusterIP
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

repoServer:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi

controller:
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
```

**Особливості конфігурації:**
- Ресурси оптимізовані для локального запуску
- Insecure mode увімкнено (для локальної розробки)
- Dex (SSO) вимкнено для спрощення

### MLflow

**Версія:** v2.8.1
**Namespace:** mlflow
**Image:** ghcr.io/mlflow/mlflow:v2.8.1

**Основні налаштування:**
```yaml
Backend Store: SQLite (/tmp/mlflow.db)
Artifact Store: Local filesystem (/tmp/artifacts)
Port: 5000
Service Type: ClusterIP

Resources:
  Requests:
    CPU: 100m
    Memory: 256Mi
  Limits:
    CPU: 300m
    Memory: 512Mi
```

**Command line аргументи:**
```bash
mlflow server \
  --host=0.0.0.0 \
  --port=5000 \
  --backend-store-uri=sqlite:///tmp/mlflow.db \
  --default-artifact-root=/tmp/artifacts \
  --serve-artifacts
```

**Важливо:** Поточна конфігурація використовує `emptyDir` volume, що означає втрату даних при перезапуску pod. Для production рекомендується:
- Використовувати PostgreSQL замість SQLite
- Налаштувати PersistentVolumeClaim
- Використовувати S3-сумісне сховище для артефактів

## Використання MLflow

### Основи роботи з MLflow

MLflow UI складається з кількох основних розділів:

1. **Experiments** - список експериментів
2. **Models** - реєстр моделей
3. **Runs** - окремі запуски експериментів з метриками

### Створення експерименту через Python

Приклад простого ML експерименту з використанням MLflow:

```python
import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score

# Встановлюємо tracking URI (замініть на ваш URL)
mlflow.set_tracking_uri("http://localhost:5000")

# Створюємо або використовуємо існуючий експеримент
mlflow.set_experiment("iris-classification")

# Завантажуємо дані
iris = load_iris()
X_train, X_test, y_train, y_test = train_test_split(
    iris.data, iris.target, test_size=0.2, random_state=42
)

# Починаємо MLflow run
with mlflow.start_run():
    # Параметри моделі
    n_estimators = 100
    max_depth = 5

    # Логуємо параметри
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)

    # Тренуємо модель
    model = RandomForestClassifier(
        n_estimators=n_estimators,
        max_depth=max_depth,
        random_state=42
    )
    model.fit(X_train, y_train)

    # Робимо передбачення
    predictions = model.predict(X_test)

    # Обчислюємо та логуємо метрики
    accuracy = accuracy_score(y_test, predictions)
    f1 = f1_score(y_test, predictions, average='weighted')

    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("f1_score", f1)

    # Зберігаємо модель
    mlflow.sklearn.log_model(model, "model")

    print(f"Accuracy: {accuracy:.4f}")
    print(f"F1 Score: {f1:.4f}")
```

### Встановлення MLflow клієнта

```bash
# Встановлення через pip
pip install mlflow

# Або через conda
conda install -c conda-forge mlflow
```

### Доступ до MLflow з коду

Якщо ви використовуєте `minikube service`, потрібно отримати URL:

```bash
# Отримуємо URL MLflow
export MLFLOW_TRACKING_URI=$(minikube service mlflow-service -n mlflow --url)
echo $MLFLOW_TRACKING_URI
```

Використовуйте цей URL у вашому Python коді:

```python
import mlflow
mlflow.set_tracking_uri("http://127.0.0.1:55432")  # Ваш URL
```

## Моніторинг та управління

### Корисні команди kubectl

```bash
# Переглянути всі ресурси в namespace
kubectl get all -n mlflow
kubectl get all -n infra-tools

# Переглянути логи MLflow
kubectl logs -f deployment/mlflow-server -n mlflow

# Переглянути логи ArgoCD
kubectl logs -f deployment/argocd-server -n infra-tools

# Описати pod (для діагностики проблем)
kubectl describe pod <pod-name> -n mlflow

# Виконати команду всередині pod
kubectl exec -it <pod-name> -n mlflow -- /bin/bash

# Перезапустити deployment
kubectl rollout restart deployment/mlflow-server -n mlflow

# Переглянути історію розгортань
kubectl rollout history deployment/mlflow-server -n mlflow

# Масштабувати deployment
kubectl scale deployment/mlflow-server -n mlflow --replicas=2
```

### Моніторинг через ArgoCD UI

1. Відкрийте ArgoCD UI: http://localhost:8080
2. Знайдіть додаток `mlflow-app`
3. Перегляньте статус синхронізації
4. Натисніть на додаток для детального огляду ресурсів

**Можливі стани:**
- **Synced** - стан у кластері відповідає Git
- **OutOfSync** - є розбіжності між Git та кластером
- **Healthy** - всі ресурси працюють коректно
- **Progressing** - розгортання у процесі

### Перевірка health status

```bash
# Статус pods
kubectl get pods -n mlflow -w  # -w для watch mode

# Events в namespace
kubectl get events -n mlflow --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n mlflow
kubectl top nodes
```

## Troubleshooting

### Проблема: Pod залишається у стані Pending

**Симптоми:**
```bash
kubectl get pods -n mlflow
NAME                             READY   STATUS    RESTARTS   AGE
mlflow-server-xxxxxxxxxx-xxxxx   0/1     Pending   0          2m
```

**Причини та рішення:**

1. **Недостатньо ресурсів у кластері**
   ```bash
   # Перевіряємо ресурси nodes
   kubectl describe nodes

   # Збільшуємо ресурси Minikube
   minikube delete
   minikube start --cpus=4 --memory=8192
   ```

2. **Проблеми з PVC (якщо використовується)**
   ```bash
   kubectl get pvc -n mlflow
   kubectl describe pvc <pvc-name> -n mlflow
   ```

### Проблема: Не можу підключитись до MLflow UI

**Симптоми:**
- Browser показує "Connection refused" або "Unable to connect"
- `minikube service` не відкриває браузер

**Рішення:**

1. **Перевірте статус service**
   ```bash
   kubectl get svc -n mlflow
   # Переконайтесь що mlflow-service існує
   ```

2. **Перевірте статус pod**
   ```bash
   kubectl get pods -n mlflow
   # Pod повинен бути Running

   # Якщо pod у стані Error або CrashLoopBackOff
   kubectl logs <pod-name> -n mlflow
   ```

3. **Використайте альтернативний метод доступу**
   ```bash
   # Спробуйте port-forward
   kubectl port-forward -n mlflow svc/mlflow-service 5000:5000
   # Відкрийте http://localhost:5000
   ```

4. **Перевірте Minikube tunnel**
   ```bash
   # Отримайте IP Minikube
   minikube ip

   # Отримайте NodePort
   kubectl get svc mlflow-service -n mlflow -o jsonpath='{.spec.ports[0].nodePort}'

   # Доступ: http://<minikube-ip>:<nodeport>
   ```

### Проблема: ArgoCD не синхронізує додатки

**Симптоми:**
- ArgoCD показує "OutOfSync" статус
- Зміни в Git не застосовуються автоматично

**Рішення:**

1. **Перевірте доступ до Git репозиторію**
   ```bash
   # Перегляньте статус репозиторію в ArgoCD
   kubectl get secret -n infra-tools
   ```

2. **Примусова синхронізація**
   ```bash
   # Через kubectl
   kubectl annotate app mlflow-app -n infra-tools \
     argocd.argoproj.io/refresh=hard --overwrite

   # Або через ArgoCD UI: натисніть "Sync" -> "Synchronize"
   ```

3. **Перевірте логи ArgoCD application controller**
   ```bash
   kubectl logs -n infra-tools \
     deployment/argocd-application-controller --tail=100
   ```

### Проблема: Втрачені дані MLflow після перезапуску

**Причина:** Використовується `emptyDir` volume, який очищається при видаленні pod.

**Рішення для локального тестування:**
Це очікувана поведінка для локального кластера. Дані зберігаються лише під час життя pod.

**Рішення для production:**
1. Створіть PersistentVolumeClaim
2. Оновіть deployment для використання PVC замість emptyDir
3. Налаштуйте S3-сумісне сховище для артефактів

### Проблема: Terraform apply fails

**Симптоми:**
```
Error: Failed to install Helm chart
```

**Рішення:**

1. **Перевірте підключення до кластера**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

2. **Оновіть Helm repositories**
   ```bash
   helm repo add argo https://argoproj.github.io/argo-helm
   helm repo update
   ```

3. **Очистіть Terraform state (якщо потрібно)**
   ```bash
   cd argocd-local
   rm -rf .terraform/
   terraform init
   terraform apply
   ```

### Проблема: Minikube не запускається

**Рішення:**

```bash
# Видаліть існуючий кластер
minikube delete

# Очистіть конфігурації
rm -rf ~/.minikube

# Запустіть заново
minikube start --cpus=2 --memory=4096
```

### Корисні діагностичні команди

```bash
# Загальний огляд кластера
kubectl get all --all-namespaces

# Детальна інформація про проблемний pod
kubectl describe pod <pod-name> -n <namespace>

# Перегляд events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Статус Minikube
minikube status
minikube logs

# Доступні addons
minikube addons list
```

## GitOps Workflow

### Як працює автоматичне розгортання

1. Ви вносите зміни в Kubernetes маніфести у директорії `applications/`
2. Комітите та пушите зміни в GitHub
3. ArgoCD автоматично виявляє зміни (кожні 3 хвилини)
4. ArgoCD застосовує зміни в Kubernetes кластер
5. Якщо щось йде не так, ArgoCD може автоматично відновити попередній стан (selfHeal)

### Приклад зміни конфігурації MLflow

1. Відкрийте файл `applications/mlflow-standalone.yaml`
2. Змініть параметр, наприклад, кількість реплік:

```yaml
spec:
  replicas: 2  # було 1
```

3. Закомітьте зміни:

```bash
git add applications/mlflow-standalone.yaml
git commit -m "Scale MLflow to 2 replicas"
git push origin lesson-7
```

4. Зачекайте 1-3 хвилини або примусово синхронізуйте в ArgoCD UI

5. Перевірте результат:

```bash
kubectl get pods -n mlflow
# Тепер має бути 2 pods
```

## Що далі?

### Ідеї для розширення проєкту

Цей проєкт є базовою інфраструктурою, яку можна розширити:

#### 1. Додати реальну ML модель
- Створіть Python додаток з training скриптом
- Інтегруйте його з MLflow для трекінгу експериментів
- Створіть Docker image та deploy в Kubernetes

#### 2. Налаштувати Persistent Storage
- Замінити emptyDir на PersistentVolumeClaim
- Налаштувати PostgreSQL для MLflow backend
- Інтегрувати MinIO (S3-compatible storage) для артефактів

#### 3. Додати CI/CD Pipeline
- GitHub Actions для автоматичного тестування
- Автоматична валідація Terraform конфігурацій
- Linting Kubernetes маніфестів

#### 4. Monitoring та Observability
- Prometheus для збору метрик
- Grafana для візуалізації
- ELK/Loki stack для централізованого логування

#### 5. Security Hardening
- Sealed Secrets для безпечного зберігання credentials
- Network Policies для обмеження трафіку
- RBAC policies для fine-grained access control
- HTTPS/TLS для ArgoCD та MLflow

#### 6. Розгортання на AWS EKS
- Використати модуль `eks/` для створення кластера
- Налаштувати AWS Load Balancer
- Інтегрувати з AWS S3 та RDS

#### 7. Model Serving
- Додати MLServer або Seldon Core
- Створити REST API для inference
- Налаштувати A/B testing

### Корисні ресурси

**Kubernetes:**
- [Official Documentation](https://kubernetes.io/docs/)
- [Kubernetes Patterns](https://k8spatterns.io/)

**ArgoCD:**
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Guide](https://www.gitops.tech/)

**MLflow:**
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [MLflow Tracking Guide](https://mlflow.org/docs/latest/tracking.html)

**Terraform:**
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

## Очищення ресурсів

Коли закінчите роботу з проєктом:

```bash
# Видалити MLflow
kubectl delete -f applications/mlflow-standalone.yaml
# або
kubectl delete -f applications/mlflow-local.yaml

# Видалити ArgoCD через Terraform
cd argocd-local
terraform destroy

# Зупинити Minikube
minikube stop

# Повністю видалити Minikube кластер
minikube delete

# Видалити Docker volumes (опціонально)
docker system prune -a --volumes
```

## Версії компонентів

| Компонент | Версія |
|-----------|--------|
| ArgoCD | v2.8.4 |
| MLflow | v2.8.1 |
| Kubernetes | 1.27+ |
| Terraform | 1.0+ |
| Helm | 3.0+ |

## Контакти та підтримка

Якщо у вас виникли питання або проблеми:

1. Перевірте розділ [Troubleshooting](#troubleshooting)
2. Створіть Issue на GitHub: [github.com/cthulhu-engineer/goit-ml-ops/issues](https://github.com/cthulhu-engineer/goit-ml-ops/issues)
3. Перегляньте існуючі Issues для схожих проблем

## Ліцензія

MIT License - детальніше у файлі LICENSE

---

**Щасливого навчання MLOps!** 🚀
