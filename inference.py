#!/usr/bin/env python3
"""
Inference script для MobileNetV2 моделі
Приймає зображення на вхід і виводить топ-3 класи
"""

import torch
import json
import sys
import os
from PIL import Image
import torchvision.transforms as transforms
import argparse

class MobileNetInference:
    def __init__(self, model_path="mobilenet_v2.pt", classes_path="imagenet_classes.json"):
        """Ініціалізація inference класу"""
        self.model_path = model_path
        self.classes_path = classes_path

        # Завантаження моделі
        print(f"Завантаження моделі з {model_path}...")
        self.model = torch.jit.load(model_path)
        self.model.eval()

        # Завантаження класів ImageNet
        with open(classes_path, 'r') as f:
            self.classes = json.load(f)

        # Визначення трансформацій для зображення
        self.transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ])

        print("Модель успішно завантажена!")

    def preprocess_image(self, image_path):
        """Попередня обробка зображення"""
        try:
            image = Image.open(image_path).convert('RGB')
            image_tensor = self.transform(image).unsqueeze(0)
            return image_tensor
        except Exception as e:
            print(f"Помилка при обробці зображення: {e}")
            return None

    def predict(self, image_path):
        """Виконання інференсу"""
        # Попередня обробка зображення
        image_tensor = self.preprocess_image(image_path)
        if image_tensor is None:
            return None

        # Виконання інференсу
        with torch.no_grad():
            outputs = self.model(image_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)

        # Отримання топ-3 результатів
        top3_prob, top3_catid = torch.topk(probabilities, 3)

        results = []
        for i in range(3):
            class_id = top3_catid[i].item()
            confidence = top3_prob[i].item()
            class_name = self.classes[class_id] if class_id < len(self.classes) else f"Unknown_{class_id}"
            results.append({
                'class_id': class_id,
                'class_name': class_name,
                'confidence': confidence
            })

        return results

    def print_results(self, results, image_path):
        """Виведення результатів"""
        print(f"\nРезультати для зображення: {image_path}")
        print("=" * 50)

        for i, result in enumerate(results, 1):
            print(f"{i}. {result['class_name']}")
            print(f"   Впевненість: {result['confidence']:.4f} ({result['confidence']*100:.2f}%)")
            print(f"   ID класу: {result['class_id']}")
            print()

def create_sample_image():
    """Створення простого тестового зображення"""
    from PIL import Image
    import numpy as np

    # Створення простого кольорового зображення
    image_array = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    image = Image.fromarray(image_array)
    sample_path = "sample_image.jpg"
    image.save(sample_path)
    print(f"Створено тестове зображення: {sample_path}")
    return sample_path

def main():
    parser = argparse.ArgumentParser(description='MobileNetV2 Inference Script')
    parser.add_argument('--image', type=str, help='Шлях до зображення для класифікації')
    parser.add_argument('--model', type=str, default='mobilenet_v2.pt',
                       help='Шлях до моделі (default: mobilenet_v2.pt)')
    parser.add_argument('--classes', type=str, default='imagenet_classes.json',
                       help='Шлях до файлу з класами (default: imagenet_classes.json)')
    parser.add_argument('--create-sample', action='store_true',
                       help='Створити тестове зображення')

    args = parser.parse_args()

    # Перевірка наявності файлів моделі та класів
    if not os.path.exists(args.model):
        print(f"Помилка: Модель {args.model} не знайдена!")
        print("Запустіть спочатку download_model.py для завантаження моделі")
        sys.exit(1)

    if not os.path.exists(args.classes):
        print(f"Помилка: Файл класів {args.classes} не знайдений!")
        print("Запустіть спочатку download_model.py для завантаження класів")
        sys.exit(1)

    # Створення тестового зображення при необхідності
    if args.create_sample:
        sample_image = create_sample_image()
        if not args.image:
            args.image = sample_image

    # Перевірка наявності зображення
    if not args.image:
        print("Помилка: Не вказано зображення для класифікації!")
        print("Використовуйте --image шлях_до_зображення або --create-sample")
        sys.exit(1)

    if not os.path.exists(args.image):
        print(f"Помилка: Зображення {args.image} не знайдене!")
        sys.exit(1)

    # Створення об'єкту для інференсу
    try:
        inferencer = MobileNetInference(args.model, args.classes)

        # Виконання класифікації
        results = inferencer.predict(args.image)

        if results:
            inferencer.print_results(results, args.image)
        else:
            print("Помилка при класифікації зображення")

    except Exception as e:
        print(f"Помилка: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()