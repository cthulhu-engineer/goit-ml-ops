# MLOps Training Automation with AWS Step Functions

Проект для автоматизації пайплайну тренування ML-моделей за допомогою AWS Step Functions, Lambda та GitHub Actions.

## Архітектура

Система складається з наступних компонентів:

1. **AWS Step Functions** - оркестрація пайплайну тренування
2. **Lambda Functions** - окремі етапи обробки (валідація, логування метрик)
3. **Terraform** - Infrastructure as Code для розгортання всієї інфраструктури
4. **GitHub Actions** - автоматичний запуск пайплайну при push

### Діаграма потоку

```
GitHub Push → GitHub Actions → Step Functions → Lambda (Validate) → Lambda (Log Metrics) → Complete
```

## Структура проєкту

```
lesson-10/
├── .github/
│   └── workflows/
│       └── mlops-pipeline.yml  # GitHub Actions workflow
├── terraform/
│   ├── main.tf              # Основна конфігурація інфраструктури
│   ├── variables.tf         # Змінні Terraform
│   ├── terraform.tf         # Конфігурація backend та providers
│   └── lambda/
│       ├── validate.py      # Lambda: валідація даних
│       ├── log_metrics.py   # Lambda: логування метрик
│       ├── validate.zip     # Архів для деплою
│       └── log_metrics.zip  # Архів для деплою
└── README.md                # Ця документація
```

## Передумови

Перед початком роботи переконайтеся, що у вас встановлено:

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- Python >= 3.11
- `zip` утиліта
- AWS акаунт з необхідними правами доступу

### AWS Permissions

Для розгортання інфраструктури потрібні наступні права:

- IAM: CreateRole, PutRolePolicy, AttachRolePolicy
- Lambda: CreateFunction, UpdateFunctionCode
- Step Functions: CreateStateMachine, UpdateStateMachine
- CloudWatch Logs: CreateLogGroup, PutRetentionPolicy
- S3: GetObject, PutObject (для Terraform state)

## Крок 1: Підготовка Lambda-функцій

### Створення ZIP-архівів

Перейдіть до директорії з Lambda функціями та створіть архіви:

```bash
cd terraform/lambda
zip validate.zip validate.py
zip log_metrics.zip log_metrics.py
```

Перевірте створені архіви:

```bash
ls -lh *.zip
```

Очікуваний вивід:

```
-rw-r--r-- 1 user user 1.1K Nov 01 19:44 log_metrics.zip
-rw-r--r-- 1 user user  764 Nov 01 19:44 validate.zip
```

## Крок 2: Конфігурація Terraform

### Налаштування змінних (опціонально)

Ви можете налаштувати змінні у файлі `terraform/variables.tf` або передати їх при виконанні команд:

```bash
# Використання змінних через CLI
terraform plan -var="project_name=my-mlops" -var="environment=prod"

# Або створіть файл terraform.tfvars
cat > terraform/terraform.tfvars <<EOF
project_name = "my-mlops-project"
environment  = "dev"
aws_region   = "us-east-1"
EOF
```

### Ініціалізація Terraform

Перейдіть до директорії terraform:

```bash
cd terraform
```

Ініціалізуйте Terraform (завантажить необхідні провайдери):

```bash
terraform init
```

### Перегляд змін

Подивіться, які ресурси будуть створені:

```bash
terraform plan
```

Terraform створить:
- 2 IAM ролі (для Lambda та Step Functions)
- 2 Lambda функції з CloudWatch Log Groups
- 1 Step Function state machine
- Необхідні IAM політики

### Розгортання інфраструктури

Застосуйте конфігурацію:

```bash
terraform apply
```

Підтвердіть створення ресурсів, ввівши `yes`.

### Збереження важливих outputs

Після успішного apply, збережіть ARN State Machine:

```bash
terraform output state_machine_arn
# Вивід: arn:aws:states:us-east-1:123456789012:stateMachine:mlops-training-auto-training-pipeline-dev
```

## Крок 3: Налаштування GitHub Actions

### Додавання секретів в GitHub

1. Перейдіть у ваш GitHub репозиторій
2. Settings → Secrets and variables → Actions → New repository secret
3. Додайте наступні секрети:

| Назва | Значення | Опис |
|------|----------|------|
| `AWS_ACCESS_KEY_ID` | Ваш AWS Access Key | Ключ доступу до AWS |
| `AWS_SECRET_ACCESS_KEY` | Ваш AWS Secret Key | Секретний ключ AWS |
| `STATE_MACHINE_ARN` | ARN з terraform output | ARN Step Functions (після першого деплою) |

### Структура GitHub Actions Workflow

Workflow складається з п'яти jobs:

1. **build-lambda** - створення ZIP-архівів Lambda функцій
2. **terraform-plan** - планування змін інфраструктури
3. **terraform-apply** - застосування змін (тільки для main гілки)
4. **train-model** - автоматичний запуск Step Functions пайплайну
5. **manual-trigger** - ручний запуск через workflow_dispatch

## Крок 4: Перевірка роботи

### Ручний запуск Step Function (через AWS CLI)

```bash
aws stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:us-east-1:ACCOUNT_ID:stateMachine:mlops-training-auto-training-pipeline-dev" \
  --name "manual-test-$(date +%s)" \
  --input '{
    "source": "manual-test",
    "commit": "abc123",
    "branch": "main"
  }'
```

### Перегляд виконання через AWS Console

1. Відкрийте [AWS Step Functions Console](https://console.aws.amazon.com/states/home)
2. Знайдіть state machine: `mlops-training-auto-training-pipeline-dev`
3. Перейдіть до вкладки "Executions"
4. Виберіть останнє виконання для перегляду деталей

### Перевірка логів Lambda

```bash
# Логи валідації
aws logs tail /aws/lambda/mlops-training-auto-data-validator-dev --follow

# Логи метрик
aws logs tail /aws/lambda/mlops-training-auto-metrics-logger-dev --follow
```

## Крок 5: Автоматичний запуск через GitHub

### Trigger через Git Push

При push до гілок `main` або `develop` автоматично запуститься workflow:

```bash
git add .
git commit -m "Update training pipeline"
git push origin main
```

### Ручний запуск workflow

1. Перейдіть у GitHub репозиторій → Actions
2. Виберіть "MLOps Training Pipeline"
3. Натисніть "Run workflow"
4. Виберіть гілку та environment (dev/staging/prod)
5. Натисніть "Run workflow"

### Моніторинг виконання

1. Відкрийте GitHub → Actions
2. Виберіть останній workflow run
3. Перегляньте логи кожного job'а
4. Перевірте Job Summary для детальної інформації

## Приклади JSON для Step Functions

### Базовий приклад

```json
{
  "source": "github-actions",
  "commit": "a1b2c3d"
}
```

### Розширений приклад (з метаданими GitHub Actions)

```json
{
  "source": "github-actions",
  "commit": "a1b2c3d4e5f6789012345678901234567890abcd",
  "commit_short": "a1b2c3d",
  "branch": "main",
  "workflow_run_id": "7654321",
  "workflow_url": "https://github.com/user/repo/actions/runs/7654321",
  "triggered_by": "username",
  "timestamp": "2025-11-01T19:45:00Z",
  "repository": "user/mlops-lesson-10"
}
```

### Приклад з параметрами тренування

```json
{
  "source": "manual-trigger",
  "commit": "latest",
  "training_config": {
    "model_type": "xgboost",
    "epochs": 100,
    "batch_size": 32,
    "learning_rate": 0.001
  }
}
```

## Очікувані результати виконання

### Успішне виконання Step Function

```json
{
  "validationResult": {
    "statusCode": 200,
    "validation_status": "PASSED",
    "checks_performed": {
      "schema_valid": true,
      "data_format_correct": true,
      "required_fields_present": true,
      "training_params_valid": true
    },
    "timestamp": "2025-11-01T19:45:30.123Z",
    "source": "gitlab-ci",
    "commit": "a1b2c3d"
  },
  "metricsResult": {
    "Payload": {
      "statusCode": 200,
      "execution_status": "SUCCESS",
      "pipeline_metadata": {
        "source": "github-actions",
        "commit": "a1b2c3d",
        "validation_status": "PASSED",
        "execution_timestamp": "2025-11-01T19:45:35.456Z"
      },
      "training_metrics": {
        "model_accuracy": 0.9234,
        "model_precision": 0.8912,
        "model_recall": 0.8756,
        "training_duration_seconds": 245,
        "training_samples": 35000,
        "validation_samples": 7500,
        "model_size_mb": 98.45
      }
    }
  }
}
```


## Очищення ресурсів

Щоб видалити всю створену інфраструктуру:

```bash
cd terraform
terraform destroy
```

Підтвердіть видалення, ввівши `yes`.

**Увага:** Це видалить всі ресурси, включаючи логи та дані!
