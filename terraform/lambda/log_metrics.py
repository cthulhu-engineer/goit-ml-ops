import json
from datetime import datetime
import random

def lambda_handler(event, context):
    """
    Logs training metrics and pipeline execution details.

    In production, this would send metrics to CloudWatch, S3, or a metrics database.
    For now, it simulates metric collection and logging.
    """

    print(f"[{datetime.utcnow().isoformat()}] Starting metrics logging...")

    # Extract validation results from previous step
    validation_status = event.get('validation_status', 'UNKNOWN')
    source = event.get('source', 'unknown')
    commit_sha = event.get('commit', 'N/A')

    print(f"Pipeline source: {source}")
    print(f"Commit SHA: {commit_sha}")
    print(f"Previous validation status: {validation_status}")

    # Simulate training metrics (in real scenario, these would come from actual training)
    simulated_metrics = {
        'model_accuracy': round(random.uniform(0.85, 0.95), 4),
        'model_precision': round(random.uniform(0.82, 0.93), 4),
        'model_recall': round(random.uniform(0.80, 0.92), 4),
        'training_duration_seconds': random.randint(120, 300),
        'training_samples': random.randint(10000, 50000),
        'validation_samples': random.randint(2000, 10000),
        'model_size_mb': round(random.uniform(50, 150), 2)
    }

    print("=" * 60)
    print("TRAINING METRICS:")
    for metric, value in simulated_metrics.items():
        print(f"  {metric}: {value}")
    print("=" * 60)

    # Prepare final result
    result = {
        "statusCode": 200,
        "execution_status": "SUCCESS",
        "pipeline_metadata": {
            "source": source,
            "commit": commit_sha,
            "validation_status": validation_status,
            "execution_timestamp": datetime.utcnow().isoformat()
        },
        "training_metrics": simulated_metrics,
        "message": "Metrics successfully logged and pipeline completed"
    }

    print(f"\n✓ Metrics logging completed successfully")
    print(f"Final result: {json.dumps(result, indent=2)}")

    return result
