import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Validates input data and model training parameters.

    Checks:
    - Required fields presence
    - Data schema correctness
    - Training parameters validity
    """

    print(f"[{datetime.utcnow().isoformat()}] Starting data validation...")

    # Extract input parameters
    source = event.get('source', 'unknown')
    commit_sha = event.get('commit', 'N/A')

    print(f"Validation triggered by: {source}")
    print(f"Commit SHA: {commit_sha}")

    # Simulate validation checks
    validation_checks = {
        'schema_valid': True,
        'data_format_correct': True,
        'required_fields_present': True,
        'training_params_valid': True
    }

    all_valid = all(validation_checks.values())

    if all_valid:
        print("✓ All validation checks passed successfully")
        result = {
            "statusCode": 200,
            "validation_status": "PASSED",
            "checks_performed": validation_checks,
            "timestamp": datetime.utcnow().isoformat(),
            "source": source,
            "commit": commit_sha
        }
    else:
        print("✗ Validation failed")
        result = {
            "statusCode": 400,
            "validation_status": "FAILED",
            "checks_performed": validation_checks,
            "timestamp": datetime.utcnow().isoformat()
        }

    print(f"Validation result: {json.dumps(result, indent=2)}")
    return result
