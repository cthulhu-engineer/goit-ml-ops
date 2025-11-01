# AWS Provider configuration
provider "aws" {
  region = var.aws_region
}

# ============================================================================
# IAM ROLE FOR LAMBDA FUNCTIONS
# ============================================================================

resource "aws_iam_role" "mlops_lambda_execution_role" {
  name               = "${var.project_name}-lambda-exec-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.mlops_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Additional policy for CloudWatch Logs (optional but recommended)
resource "aws_iam_role_policy" "lambda_cloudwatch_policy" {
  name = "${var.project_name}-lambda-cloudwatch-${var.environment}"
  role = aws_iam_role.mlops_lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# ============================================================================
# LAMBDA FUNCTION: DATA VALIDATION
# ============================================================================

resource "aws_lambda_function" "data_validation_function" {
  filename         = "${path.module}/lambda/validate.zip"
  function_name    = "${var.project_name}-data-validator-${var.environment}"
  role             = aws_iam_role.mlops_lambda_execution_role.arn
  handler          = "validate.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 60
  memory_size      = 256
  source_code_hash = filebase64sha256("${path.module}/lambda/validate.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  tags = {
    Name        = "${var.project_name}-validator"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for validation function
resource "aws_cloudwatch_log_group" "validation_logs" {
  name              = "/aws/lambda/${aws_lambda_function.data_validation_function.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-validation-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================================================
# LAMBDA FUNCTION: METRICS LOGGING
# ============================================================================

resource "aws_lambda_function" "metrics_logging_function" {
  filename         = "${path.module}/lambda/log_metrics.zip"
  function_name    = "${var.project_name}-metrics-logger-${var.environment}"
  role             = aws_iam_role.mlops_lambda_execution_role.arn
  handler          = "log_metrics.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 90
  memory_size      = 512
  source_code_hash = filebase64sha256("${path.module}/lambda/log_metrics.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  tags = {
    Name        = "${var.project_name}-metrics-logger"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for metrics function
resource "aws_cloudwatch_log_group" "metrics_logs" {
  name              = "/aws/lambda/${aws_lambda_function.metrics_logging_function.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-metrics-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================================================
# IAM ROLE FOR STEP FUNCTIONS
# ============================================================================

resource "aws_iam_role" "stepfunctions_execution_role" {
  name               = "${var.project_name}-stepfn-exec-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.stepfn_assume_role_policy.json

  tags = {
    Name        = "${var.project_name}-stepfn-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_policy_document" "stepfn_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "stepfn_lambda_invoke_policy" {
  name = "${var.project_name}-stepfn-lambda-invoke-${var.environment}"
  role = aws_iam_role.stepfunctions_execution_role.id

  policy = data.aws_iam_policy_document.stepfn_lambda_policy.json
}

data "aws_iam_policy_document" "stepfn_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.data_validation_function.arn,
      aws_lambda_function.metrics_logging_function.arn,
      "${aws_lambda_function.data_validation_function.arn}:*",
      "${aws_lambda_function.metrics_logging_function.arn}:*"
    ]
  }
}

# ============================================================================
# STEP FUNCTIONS STATE MACHINE
# ============================================================================

resource "aws_sfn_state_machine" "mlops_training_pipeline" {
  name     = "${var.project_name}-training-pipeline-${var.environment}"
  role_arn = aws_iam_role.stepfunctions_execution_role.arn

  definition = jsonencode({
    Comment = "MLOps Training Pipeline - Validates data and logs metrics"
    StartAt = "ValidateTrainingData"
    States = {
      ValidateTrainingData = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.data_validation_function.arn
          Payload = {
            "source.$"  = "$.source"
            "commit.$"  = "$.commit"
          }
        }
        ResultPath = "$.validationResult"
        ResultSelector = {
          "statusCode.$"         = "$.Payload.statusCode"
          "validation_status.$"  = "$.Payload.validation_status"
          "checks_performed.$"   = "$.Payload.checks_performed"
          "timestamp.$"          = "$.Payload.timestamp"
          "source.$"             = "$.Payload.source"
          "commit.$"             = "$.Payload.commit"
        }
        Next = "LogTrainingMetrics"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ValidationFailed"
            ResultPath  = "$.error"
          }
        ]
      }

      LogTrainingMetrics = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.metrics_logging_function.arn
          Payload = {
            "validation_status.$" = "$.validationResult.validation_status"
            "source.$"            = "$.validationResult.source"
            "commit.$"            = "$.validationResult.commit"
          }
        }
        ResultPath = "$.metricsResult"
        End        = true
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "MetricsLoggingFailed"
            ResultPath  = "$.error"
          }
        ]
      }

      ValidationFailed = {
        Type = "Fail"
        Error = "ValidationError"
        Cause = "Data validation step failed"
      }

      MetricsLoggingFailed = {
        Type = "Fail"
        Error = "MetricsError"
        Cause = "Metrics logging step failed"
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-pipeline"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.mlops_training_pipeline.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.mlops_training_pipeline.name
}

output "validation_lambda_arn" {
  description = "ARN of the validation Lambda function"
  value       = aws_lambda_function.data_validation_function.arn
}

output "metrics_lambda_arn" {
  description = "ARN of the metrics logging Lambda function"
  value       = aws_lambda_function.metrics_logging_function.arn
}
