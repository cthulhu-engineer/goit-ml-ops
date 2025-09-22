# ML-сервіс контейнеризація з PyTorch MobileNetV2

Проект демонструє створення та оптимізацію Docker образів для ML inference сервісу з використанням PyTorch MobileNetV2.

## 📋 Огляд проекту

- **Модель**: MobileNetV2 (TorchScript format)
- **Задача**: Класифікація зображень ImageNet
- **Образи**: Fat (2.99GB) vs Slim (1.10GB)
- **Оптимізація**: Multi-stage Docker build (-63% розміру)

## 🚀 Швидкий старт

### 1. Підготовка середовища

```bash
# Запуск скрипта встановлення залежностей
chmod +x install_dev_tools.sh
./install_dev_tools.sh

# Або ручне встановлення
sudo apt update
sudo apt install -y docker.io python3 python3-pip
```

### 2. Завантаження моделі

```bash
# Створення віртуального середовища
python3 -m venv venv
source venv/bin/activate

# Встановлення залежностей
pip install torch torchvision pillow

# Завантаження MobileNetV2 моделі
python3 download_model.py
```

### 3. Тестування локально

```bash
# Запуск inference з тестовим зображенням
python3 inference.py --create-sample

# Запуск з власним зображенням
python3 inference.py --image path/to/your/image.jpg
```

## 🐳 Docker образи

### Побудова образів

```bash
# Fat образ (повнофункціональний)
docker build -f Dockerfile.fat -t mobilenet-fat:latest .

# Slim образ (оптимізований)
docker build -f Dockerfile.slim -t mobilenet-slim:latest .
```

### Запуск контейнерів

```bash
# Fat образ
docker run --rm mobilenet-fat:latest python3 /app/inference.py --create-sample

# Slim образ
docker run --rm mobilenet-slim:latest python /app/inference.py --create-sample

# З власним зображенням
docker run --rm -v $(pwd)/my_image.jpg:/app/input.jpg \
  mobilenet-slim:latest python /app/inference.py --image /app/input.jpg
```

## 📁 Структура проекту

```
lesson-3/
├── README.md                   # Цей файл
├── report.md                   # Детальний звіт з аналізом
├── install_dev_tools.sh        # Скрипт встановлення середовища
├── download_model.py           # Завантаження MobileNetV2 моделі
├── inference.py               # ML inference сервіс
├── Dockerfile.fat             # Fat Docker образ (2.99GB)
├── Dockerfile.slim            # Slim Docker образ (1.10GB)
├── .dockerignore              # Docker build контекст
└── .gitignore                 # Git ignore правила
```

## 🛠️ Опції inference.py

```bash
# Показати довідку
python3 inference.py --help

# Створити тестове зображення та класифікувати
python3 inference.py --create-sample

# Класифікувати власне зображення
python3 inference.py --image path/to/image.jpg

# Вказати шляхи до моделі та класів
python3 inference.py --image image.jpg --model model.pt --classes classes.json
```

## 🔍 Порівняння образів

| Характеристика | Fat образ | Slim образ |
|----------------|-----------|------------|
| **Розмір** | 2.99 GB | 1.10 GB |
| **Базовий образ** | Ubuntu 22.04 | Python 3.11-slim |
| **Інструменти розробки** | ✅ Повний набір | ❌ Мінімум |
| **ML бібліотеки** | ✅ Розширені | ✅ Базові |
| **Production ready** | ❌ Великий розмір | ✅ Оптимізований |
| **Debug можливості** | ✅ Повні | ❌ Обмежені |

## 🎯 Сценарії використання

### Fat образ рекомендується для:
- Локальної розробки та експериментів
- Jupyter notebook досліджень
- Налагодження та профілювання
- Навчального процесу

### Slim образ рекомендується для:
- Production deployments
- CI/CD pipelines
- Kubernetes кластерів
- Resource-constrained середовищ

## 📊 Результати оптимізації

- **Зменшення розміру**: 63% (1.89 GB економії)
- **Підхід**: Multi-stage Docker build
- **Функціональність**: Збережена повністю
- **Безпека**: Non-root користувач, мінімальна attack surface

## 🔧 Налаштування

### Змінні середовища

```bash
MODEL_PATH=/app/mobilenet_v2.pt      # Шлях до моделі
CLASSES_PATH=/app/imagenet_classes.json  # Шлях до класів ImageNet
PYTHONPATH=/app                      # Python module path
```

### Порти

- `8000/tcp` - Зарезервований для майбутніх веб-сервісів

## 🐛 Усунення проблем

### Проблема: "No module named 'torch'"
```bash
# Встановіть PyTorch
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
```

### Проблема: "Model file not found"
```bash
# Завантажте модель
python3 download_model.py
```

### Проблема: Docker permission denied
```bash
# Додайте користувача до групи docker
sudo usermod -aG docker $USER
newgrp docker
```

## 📚 Додаткові ресурси

- [PyTorch документація](https://pytorch.org/docs/)
- [TorchVision моделі](https://pytorch.org/vision/stable/models.html)
- [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage builds](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/#use-multi-stage-builds)

## 📄 Ліцензія

Проект створено для навчальних цілей в рамках курсу MLOps.

## 👤 Автор

**Oleh Kilaru**
