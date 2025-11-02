import numpy as np
import pandas as pd
import pickle
import json
from datetime import datetime
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix

class SensorAnomalyTrainer:
    """Train Isolation Forest model for IoT sensor anomaly detection"""

    def __init__(self, contamination=0.15, random_state=42):
        self.contamination = contamination
        self.random_state = random_state
        self.model = None
        self.scaler = None
        self.feature_names = [
            'temperature', 'humidity', 'pressure', 'vibration', 'hour_of_day'
        ]

    def create_synthetic_dataset(self, n_samples=2000):
        """Generate synthetic IoT sensor data"""
        np.random.seed(self.random_state)

        # Normal data (85%)
        n_normal = int(n_samples * 0.85)
        normal_data = {
            'temperature': np.random.normal(22, 3, n_normal),
            'humidity': np.random.normal(55, 10, n_normal),
            'pressure': np.random.normal(1013, 5, n_normal),
            'vibration': np.random.exponential(0.5, n_normal),
            'hour_of_day': np.random.randint(0, 24, n_normal)
        }

        # Anomalous data (15%)
        n_anomaly = n_samples - n_normal
        anomaly_data = {
            'temperature': np.concatenate([
                np.random.normal(35, 5, n_anomaly // 3),
                np.random.normal(5, 3, n_anomaly // 3),
                np.random.normal(22, 3, n_anomaly - 2 * (n_anomaly // 3))
            ]),
            'humidity': np.concatenate([
                np.random.normal(90, 5, n_anomaly // 3),
                np.random.normal(15, 5, n_anomaly // 3),
                np.random.normal(55, 10, n_anomaly - 2 * (n_anomaly // 3))
            ]),
            'pressure': np.concatenate([
                np.random.normal(1040, 10, n_anomaly // 2),
                np.random.normal(980, 10, n_anomaly - n_anomaly // 2)
            ]),
            'vibration': np.concatenate([
                np.random.exponential(3, n_anomaly // 2),
                np.random.exponential(0.5, n_anomaly - n_anomaly // 2)
            ]),
            'hour_of_day': np.random.randint(0, 24, n_anomaly)
        }

        # Combine datasets
        X = pd.DataFrame({
            feature: np.concatenate([normal_data[feature], anomaly_data[feature]])
            for feature in self.feature_names
        })

        # Labels: 1 = normal, -1 = anomaly
        y = np.concatenate([
            np.ones(n_normal),
            -np.ones(n_anomaly)
        ])

        return X, y

    def train_model(self, X, y):
        """Train Isolation Forest model"""
        print(f"Training model on {len(X)} samples...")

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.3, random_state=self.random_state, stratify=y
        )

        # Scale features
        self.scaler = StandardScaler()
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)

        # Train model
        self.model = IsolationForest(
            contamination=self.contamination,
            random_state=self.random_state,
            n_estimators=100
        )
        self.model.fit(X_train_scaled)

        # Evaluate
        y_train_pred = self.model.predict(X_train_scaled)
        y_test_pred = self.model.predict(X_test_scaled)

        print("\n=== Training Set Performance ===")
        print(classification_report(y_train, y_train_pred,
                                   target_names=['Anomaly', 'Normal']))
        print("\nConfusion Matrix:")
        print(confusion_matrix(y_train, y_train_pred))

        print("\n=== Test Set Performance ===")
        print(classification_report(y_test, y_test_pred,
                                   target_names=['Anomaly', 'Normal']))
        print("\nConfusion Matrix:")
        print(confusion_matrix(y_test, y_test_pred))

        # Calculate accuracies
        train_accuracy = (y_train == y_train_pred).mean()
        test_accuracy = (y_test == y_test_pred).mean()

        print(f"\nTrain Accuracy: {train_accuracy:.4f}")
        print(f"Test Accuracy: {test_accuracy:.4f}")

        return {
            'train_accuracy': float(train_accuracy),
            'test_accuracy': float(test_accuracy),
            'n_samples': len(X),
            'n_features': len(self.feature_names),
            'contamination': self.contamination
        }

    def save_model(self, model_path='model', metadata=None):
        """Save trained model and scaler"""
        import os
        os.makedirs(model_path, exist_ok=True)

        # Save model
        with open(f'{model_path}/isolation_forest_model.pkl', 'wb') as f:
            pickle.dump(self.model, f)

        # Save scaler
        with open(f'{model_path}/feature_scaler.pkl', 'wb') as f:
            pickle.dump(self.scaler, f)

        # Save metadata
        if metadata:
            metadata['timestamp'] = datetime.now().isoformat()
            metadata['features'] = self.feature_names
            with open(f'{model_path}/model_metadata.json', 'w') as f:
                json.dump(metadata, f, indent=2)

        print(f"\nModel saved to {model_path}/")

def main():
    """Main training pipeline"""
    print("IoT Sensor Anomaly Detection - Model Training")
    print("=" * 50)

    # Initialize trainer
    trainer = SensorAnomalyTrainer(contamination=0.15, random_state=42)

    # Generate data
    print("\nGenerating synthetic sensor data...")
    X, y = trainer.create_synthetic_dataset(n_samples=2000)

    print(f"Dataset shape: {X.shape}")
    print(f"Normal samples: {(y == 1).sum()}")
    print(f"Anomaly samples: {(y == -1).sum()}")

    # Train model
    metrics = trainer.train_model(X, y)

    # Save model
    trainer.save_model(model_path='model', metadata=metrics)

    print("\n✅ Training complete!")

if __name__ == "__main__":
    main()
