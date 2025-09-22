#!/bin/bash

# Bash-скрипт для встановлення середовища DevOps та ML-розробки
# Автор: Oleh Kilaru

set -e  # Вихід при помилці

LOG_FILE="install.log"

# Функція для логування
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Функція для перевірки версії команди
check_version() {
    local cmd="$1"
    local version_arg="$2"
    local expected_version="$3"

    if command -v "$cmd" &> /dev/null; then
        local current_version
        current_version=$($cmd $version_arg 2>/dev/null | head -1)
        log "✓ $cmd встановлено: $current_version"
        return 0
    else
        log "✗ $cmd не знайдено"
        return 1
    fi
}

# Функція для перевірки Python версії
check_python_version() {
    if command -v python3 &> /dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        local major_version=$(echo "$python_version" | cut -d'.' -f1)
        local minor_version=$(echo "$python_version" | cut -d'.' -f2)

        if [[ "$major_version" -eq 3 && "$minor_version" -ge 9 ]]; then
            log "✓ Python $python_version встановлено (>= 3.9)"
            return 0
        else
            log "✗ Python $python_version < 3.9"
            return 1
        fi
    else
        log "✗ Python3 не знайдено"
        return 1
    fi
}

# Функція для перевірки Python пакету
check_python_package() {
    local package="$1"
    if python3 -c "import $package" 2>/dev/null; then
        local version=$(python3 -c "import $package; print(getattr($package, '__version__', 'unknown'))" 2>/dev/null)
        log "✓ $package встановлено: $version"
        return 0
    else
        log "✗ $package не знайдено"
        return 1
    fi
}

log "=== Початок встановлення середовища DevOps та ML ==="

# Оновлення списку пакетів
log "Оновлення списку пакетів..."
sudo apt update

# Встановлення базових залежностей
log "Встановлення базових залежностей..."
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# Перевірка та встановлення Docker
if ! check_version "docker" "--version"; then
    log "Встановлення Docker..."

    # Додавання Docker GPG ключа
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Додавання Docker репозиторію
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Додавання користувача до групи docker
    sudo usermod -aG docker $USER

    log "Docker встановлено. Перезайдіть в систему для застосування змін."
else
    log "Docker вже встановлено"
fi

# Перевірка та встановлення Docker Compose
if ! check_version "docker-compose" "--version"; then
    log "Встановлення Docker Compose..."

    # Завантаження останньої версії Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    log "Docker Compose встановлено"
else
    log "Docker Compose вже встановлено"
fi

# Перевірка та встановлення Python >= 3.9
if ! check_python_version; then
    log "Встановлення Python 3.9..."
    sudo apt install -y python3.9 python3.9-venv python3.9-dev

    # Встановлення python3.9 як альтернативу за замовчуванням
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

    log "Python 3.9 встановлено"
else
    log "Python >= 3.9 вже встановлено"
fi

# Перевірка та встановлення pip
if ! check_version "pip3" "--version"; then
    log "Встановлення pip..."
    sudo apt install -y python3-pip

    log "pip встановлено"
else
    log "pip вже встановлено"
fi

# Оновлення pip до останньої версії
log "Оновлення pip..."
python3 -m pip install --upgrade pip

# Перевірка та встановлення Django
if ! check_python_package "django"; then
    log "Встановлення Django..."
    python3 -m pip install Django
    log "Django встановлено"
else
    log "Django вже встановлено"
fi

# Перевірка та встановлення PyTorch
if ! check_python_package "torch"; then
    log "Встановлення PyTorch..."
    python3 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    log "PyTorch встановлено"
else
    log "PyTorch вже встановлено"
fi

# Перевірка та встановлення torchvision
if ! check_python_package "torchvision"; then
    log "Встановлення torchvision..."
    python3 -m pip install torchvision
    log "torchvision встановлено"
else
    log "torchvision вже встановлено"
fi

# Перевірка та встановлення Pillow
if ! check_python_package "PIL"; then
    log "Встановлення Pillow..."
    python3 -m pip install Pillow
    log "Pillow встановлено"
else
    log "Pillow вже встановлено"
fi

log "=== Фінальна перевірка встановлених інструментів ==="

# Фінальна перевірка всіх інструментів
check_version "docker" "--version"
check_version "docker-compose" "--version"
check_python_version
check_version "pip3" "--version"
check_python_package "django"
check_python_package "torch"
check_python_package "torchvision"
check_python_package "PIL"

log "=== Встановлення завершено ==="
log "Примітка: Якщо Docker було щойно встановлено, перезайдіть в систему для застосування змін групи docker"

echo "Встановлення завершено! Перегляньте файл $LOG_FILE для деталей."
