import os
import pickle
import logging
from datetime import datetime
from typing import Dict, Any
import numpy as np
from fastapi import FastAPI, HTTPException
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
async def predict(data: SensorData):
    """Detect anomalies in sensor data"""
    start_time = datetime.now()

    try:
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

        # Update metrics
        anomaly_detections.labels(
            result='anomaly' if is_anomaly else 'normal'
        ).inc()

        active_sensors.inc()

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

        log.info(f"Prediction: {'ANOMALY' if is_anomaly else 'NORMAL'}, "
                f"confidence: {confidence:.4f}")

        return result

    except Exception as e:
        log.error(f"Prediction error: {e}")
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
