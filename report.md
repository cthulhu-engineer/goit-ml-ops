# Звіт з контейнеризації ML-сервісу

## Огляд завдання

Метою цього проекту було створення та порівняння двох варіантів Docker-образів для PyTorch MobileNetV2 inference сервісу:
- **Fat образ** - повнофункціональний образ з усіма інструментами розробки
- **Slim образ** - оптимізований образ з мінімальним набором залежностей

## Реалізація

### 1. Підготовка середовища

Створено Bash-скрипт `install_dev_tools.sh` для автоматизованого встановлення:
- Docker/Podman та Docker Compose
- Python ≥ 3.9
- ML-залежності: PyTorch, TorchVision, Pillow
- Додаткові пакети для розробки

**Особливості скрипта:**
- Ідемпотентність - безпечне повторне виконання
- Логування всіх операцій у `install.log`
- Перевірка версій після встановлення
- Підтримка різних дистрибутивів Linux

### 2. ML-модель та inference

**Модель:** MobileNetV2 з torchvision, збережена у форматі TorchScript (`.pt`)

**Inference сервіс (`inference.py`):**
- Завантаження TorchScript моделі
- Попередня обробка зображень (resize, normalize)
- Класифікація з виведенням топ-3 результатів
- Підтримка командного рядка
- Створення тестових зображень

## Порівняння Docker образів

### Технічні характеристики

| Параметр | Fat образ | Slim образ | Економія |
|----------|-----------|------------|----------|
| **Розмір** | 2.99 GB | 1.10 GB | **63.2%** |
| **Базовий образ** | Ubuntu 22.04 | Python 3.11-slim | - |
| **Кількість шарів** | 28 | 29 | -3.6% |
| **Архітектура** | Monolithic | Multi-stage | - |

### Детальний аналіз

#### Fat образ (2.99 GB)
**Переваги:**
- Повний набір системних інструментів (vim, nano, htop, git, curl)
- Інструменти розробки (build-essential, cmake)
- ML-екосистема (scipy, pandas, matplotlib, scikit-learn)
- Веб-фреймворки (Flask, FastAPI)
- Jupyter notebook для дослідження
- Debugging інструменти (gdb, strace)

**Недоліки:**
- Великий розмір (майже 3 GB)
- Довгий час завантаження
- Зайві залежності для production

**Структура шарів:**
```
- Ubuntu 22.04 base (72 MB)
- System packages (580 MB)
- Python development tools (150 MB)
- PyTorch + ML libraries (1.8 GB)
- Additional packages (400 MB)
```

#### Slim образ (1.10 GB)
**Переваги:**
- Компактний розмір (на 63% менший)
- Multi-stage build - оптимізована збірка
- Мінімальні runtime залежності
- Швидше завантаження
- Підходить для production

**Недоліки:**
- Відсутні інструменти для debugging
- Неможливо встановлювати додаткові пакети без перебудови
- Обмежені можливості для розробки

**Multi-stage архітектура:**
```
Stage 1 (Builder):
- Python 3.11-slim base
- Build tools (gcc, python3-dev)
- Compilation dependencies
- PyTorch installation

Stage 2 (Runtime):
- Clean Python 3.11-slim base
- Copied virtual environment
- Only inference.py + model
- Minimal runtime libraries
```

### Функціональність

**Обидва образи успішно виконують inference:**

Fat образ:
```
1. doormat - 6.58%
2. matchstick - 6.45%
3. binder - 3.37%
```

Slim образ:
```
1. doormat - 9.98%
2. matchstick - 5.57%
3. wool - 5.11%
```

### Безпека та архітектура

**Спільні характеристики:**
- Non-root користувач (`appuser`)
- Healthcheck для Slim образу
- Мінімальні exposed порти
- Чіткі змінні середовища

**Відмінності:**
- Fat: більше attack surface через додаткові інструменти
- Slim: мінімальна attack surface, краща ізоляція

## Рекомендації з оптимізації

### Подальші покращення Slim образу

1. **Distroless image:** Використання Google Distroless для ще більшого зменшення
2. **Alpine Linux:** Альтернатива з меншим базовим образом
3. **Model optimization:** Квантизація моделі для зменшення розміру
4. **Layer caching:** Оптимізація порядку COPY команд
5. **Multi-arch builds:** Підтримка ARM64 для cloud deployments

### Сценарії використання

**Fat образ підходить для:**
- Локальної розробки
- Експериментів з моделями
- Jupyter notebook досліджень
- Прототипування
- Навчального процесу

**Slim образ підходить для:**
- Production deployments
- CI/CD pipelines
- Kubernetes/cloud environments
- Microservices архітектури
- Resource-constrained environments

## Висновки

1. **Оптимізація розміру:** Multi-stage підхід дозволив досягти 63% зменшення розміру образу
2. **Performance:** Обидва образи показують однакову функціональність inference
3. **Trade-offs:** Fat образ жертвує розміром заради зручності розробки
4. **Production ready:** Slim образ готовий для production використання
