#!/usr/bin/env python3
"""
Скрипт для завантаження та збереження моделі MobileNetV2 у форматі TorchScript
"""

import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import json
import urllib.request
import os

def download_model():
    """Завантажує модель MobileNetV2 та зберігає її у форматі TorchScript"""

    print("Завантаження моделі MobileNetV2...")

    # Завантаження попередньо навченої моделі
    model = models.mobilenet_v2(pretrained=True)
    model.eval()

    # Створення dummy input для трасування
    dummy_input = torch.randn(1, 3, 224, 224)

    # Конвертація моделі до TorchScript
    print("Конвертація до TorchScript...")
    traced_model = torch.jit.trace(model, dummy_input)

    # Збереження моделі
    model_path = "mobilenet_v2.pt"
    traced_model.save(model_path)
    print(f"Модель збережено як {model_path}")

    # Завантаження ImageNet класів
    if not os.path.exists("imagenet_classes.json"):
        print("Завантаження класів ImageNet...")
        url = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"
        with urllib.request.urlopen(url) as response:
            classes = [line.decode('utf-8').strip() for line in response.readlines()]

        with open("imagenet_classes.json", "w") as f:
            json.dump(classes, f, indent=2)
        print("Класи ImageNet збережено у imagenet_classes.json")

    return model_path

def test_model(model_path):
    """Тестує збережену модель"""
    print(f"\nТестування моделі {model_path}...")

    # Завантаження моделі
    model = torch.jit.load(model_path)
    model.eval()

    # Тестовий вхід
    test_input = torch.randn(1, 3, 224, 224)

    with torch.no_grad():
        output = model(test_input)
        print(f"Розмір виходу: {output.shape}")
        print(f"Перші 5 значень: {output[0][:5].tolist()}")

    print("Модель працює коректно!")

if __name__ == "__main__":
    model_path = download_model()
    test_model(model_path)