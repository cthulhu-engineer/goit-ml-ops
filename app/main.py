import os
import pickle
import logging
import json
import requests
from datetime import datetime
from typing import Dict, Any, List
from collections import deque
import numpy as np
from scipy import stats
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi.responses import Response

# Logging setup
logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="Sensor Quality Monitoring API",
    description="IoT sensor anomaly detection service with drift monitoring",
    version="1.0.0"
)

# Prometheus metrics
api_requests_total = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)
api_request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration'
)
anomaly_detections = Counter(
    'anomaly_detections_total',
    'Total anomaly detections',
    ['result']
)
drift_events = Counter(
    'drift_events_total',
    'Data drift detection events'
)
active_sensors = Gauge(
    'active_sensors',
    'Number of active sensors'
)

# Request/Response models
class SensorData(BaseModel):
    temperature: float = Field(..., ge=-50, le=100)
    humidity: float = Field(..., ge=0, le=100)
    pressure: float = Field(..., ge=900, le=1100)
    vibration: float = Field(..., ge=0, le=10)
    hour_of_day: int = Field(..., ge=0, le=23)

class PredictionResult(BaseModel):
    anomaly: bool
    confidence: float
    timestamp: str
    sensor_data: Dict[str, float]

# Model loading
model = None
scaler = None

# Drift detection
DRIFT_WINDOW_SIZE = 100
DRIFT_THRESHOLD = 0.05  # p-value threshold for KS test
ANOMALY_RATE_THRESHOLD = 0.30  # 30% anomaly rate triggers retrain

reference_data = deque(maxlen=1000)  # Reference distribution
current_window = deque(maxlen=DRIFT_WINDOW_SIZE)
anomaly_count = 0
total_predictions = 0

class DriftDetector:
    """Statistical drift detection using Kolmogorov-Smirnov test"""

    @staticmethod
    def detect_drift(reference: np.ndarray, current: np.ndarray) -> tuple:
        """
        Detect drift using KS test for each feature
        Returns: (drift_detected, p_values)
        """
        if len(reference) < 30 or len(current) < 30:
            return False, []

        p_values = []
        for i in range(reference.shape[1]):
            statistic, p_value = stats.ks_2samp(reference[:, i], current[:, i])
            p_values.append(p_value)

        # Drift detected if any feature has p-value < threshold
        drift_detected = any(p < DRIFT_THRESHOLD for p in p_values)
        return drift_detected, p_values

    @staticmethod
    def trigger_retrain(reason: str):
        """Trigger GitHub Actions retrain workflow via webhook"""
        github_token = os.getenv('GITHUB_TOKEN')
        repo = os.getenv('GITHUB_REPOSITORY', 'cthulhu-engineer/goit-ml-ops')

        if not github_token:
            log.warning("GITHUB_TOKEN not set, cannot trigger retrain")
            log.info(f"🔄 RETRAIN TRIGGER: {reason}")
            return

        try:
            url = f"https://api.github.com/repos/{repo}/actions/workflows/retrain.yml/dispatches"
            headers = {
                'Authorization': f'token {github_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            data = {
                'ref': 'final-project',
                'inputs': {'reason': reason}
            }
            response = requests.post(url, headers=headers, json=data, timeout=10)
            response.raise_for_status()
            log.info(f"✅ Retrain workflow triggered: {reason}")
        except Exception as e:
            log.error(f"Failed to trigger retrain: {e}")

def initialize_model():
    """Load trained model and scaler"""
    global model, scaler

    model_path = "model/isolation_forest_model.pkl"
    scaler_path = "model/feature_scaler.pkl"

    try:
        with open(model_path, 'rb') as f:
            model = pickle.load(f)
        with open(scaler_path, 'rb') as f:
            scaler = pickle.load(f)
        log.info("Model and scaler loaded successfully")
    except FileNotFoundError as e:
        log.error(f"Model files not found: {e}")
        raise RuntimeError("Model not available")

@app.on_event("startup")
async def startup():
    """Initialize on startup"""
    initialize_model()
    active_sensors.set(0)

@app.get("/")
async def root():
    """Root endpoint"""
    api_requests_total.labels(method='GET', endpoint='/', status='200').inc()
    return {
        "service": "Sensor Quality Monitoring API",
        "version": "1.0.0",
        "status": "operational"
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    api_requests_total.labels(method='GET', endpoint='/health', status='200').inc()

    health_status = {
        "status": "healthy",
        "model_loaded": model is not None,
        "scaler_loaded": scaler is not None,
        "timestamp": datetime.now().isoformat()
    }

    if not (model and scaler):
        raise HTTPException(status_code=503, detail="Model not loaded")

    return health_status

@app.post("/detect", response_model=PredictionResult)
async def predict(data: SensorData, background_tasks: BackgroundTasks):
    """Detect anomalies in sensor data with drift monitoring"""
    global anomaly_count, total_predictions
    start_time = datetime.now()

    try:
        # Log incoming data
        log.info(f"📥 Incoming data: temp={data.temperature}, "
                f"humidity={data.humidity}, pressure={data.pressure}, "
                f"vibration={data.vibration}, hour={data.hour_of_day}")

        # Prepare features
        features = np.array([[
            data.temperature,
            data.humidity,
            data.pressure,
            data.vibration,
            data.hour_of_day
        ]])

        # Scale features
        features_scaled = scaler.transform(features)

        # Predict
        prediction = model.predict(features_scaled)[0]
        score = model.score_samples(features_scaled)[0]

        is_anomaly = prediction == -1
        confidence = abs(float(score))

        # Store data for drift detection
        reference_data.append(features[0])
        current_window.append(features[0])

        # Update anomaly tracking
        total_predictions += 1
        if is_anomaly:
            anomaly_count += 1

        # Update metrics
        anomaly_detections.labels(
            result='anomaly' if is_anomaly else 'normal'
        ).inc()

        # Check for drift (every DRIFT_WINDOW_SIZE predictions)
        if len(current_window) == DRIFT_WINDOW_SIZE and len(reference_data) >= DRIFT_WINDOW_SIZE:
            ref_array = np.array(list(reference_data)[:DRIFT_WINDOW_SIZE])
            curr_array = np.array(list(current_window))

            drift_detected, p_values = DriftDetector.detect_drift(ref_array, curr_array)

            if drift_detected:
                drift_events.inc()
                log.warning(f"⚠️ DRIFT DETECTED! p-values: {p_values}")
                background_tasks.add_task(
                    DriftDetector.trigger_retrain,
                    f"Data drift detected (p-values: {p_values})"
                )

        # Check anomaly rate
        if total_predictions >= 100:
            anomaly_rate = anomaly_count / total_predictions
            if anomaly_rate > ANOMALY_RATE_THRESHOLD:
                log.warning(f"⚠️ HIGH ANOMALY RATE: {anomaly_rate:.2%}")
                background_tasks.add_task(
                    DriftDetector.trigger_retrain,
                    f"High anomaly rate: {anomaly_rate:.2%}"
                )
                # Reset counters
                anomaly_count = 0
                total_predictions = 0

        # Track request duration
        duration = (datetime.now() - start_time).total_seconds()
        api_request_duration.observe(duration)
        api_requests_total.labels(
            method='POST',
            endpoint='/detect',
            status='200'
        ).inc()

        result = PredictionResult(
            anomaly=bool(is_anomaly),
            confidence=confidence,
            timestamp=datetime.now().isoformat(),
            sensor_data=data.dict()
        )

        log.info(f"📤 Prediction: {'🔴 ANOMALY' if is_anomaly else '🟢 NORMAL'}, "
                f"confidence: {confidence:.4f}, anomaly_rate: {anomaly_count}/{total_predictions}")

        return result

    except Exception as e:
        log.error(f"❌ Prediction error: {e}")
        api_requests_total.labels(
            method='POST',
            endpoint='/detect',
            status='500'
        ).inc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        content=generate_latest(),
        media_type="text/plain"
    )

@app.get("/stats")
async def statistics():
    """Get service statistics"""
    api_requests_total.labels(method='GET', endpoint='/stats', status='200').inc()

    return {
        "timestamp": datetime.now().isoformat(),
        "model_type": "Isolation Forest",
        "features": ["temperature", "humidity", "pressure", "vibration", "hour_of_day"],
        "service_info": {
            "name": "Sensor Quality Monitoring",
            "version": "1.0.0"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
