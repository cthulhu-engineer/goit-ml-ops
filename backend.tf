# ========================================
# Terraform Backend Configuration
# ========================================

# Local backend for development/testing
# This is suitable for learning and local development
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ========================================
# Production S3 Backend Configuration
# ========================================
#
# For production environments, use S3 backend with DynamoDB for state locking
#
# Prerequisites:
# 1. Create an S3 bucket for state storage:
#    aws s3 mb s3://my-terraform-state-bucket-<ACCOUNT_ID> --region us-east-1
#
# 2. Enable versioning on the bucket:
#    aws s3api put-bucket-versioning \
#      --bucket my-terraform-state-bucket-<ACCOUNT_ID> \
#      --versioning-configuration Status=Enabled
#
# 3. Enable encryption:
#    aws s3api put-bucket-encryption \
#      --bucket my-terraform-state-bucket-<ACCOUNT_ID> \
#      --server-side-encryption-configuration '{
#        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
#      }'
#
# 4. Create DynamoDB table for state locking:
#    aws dynamodb create-table \
#      --table-name terraform-state-lock \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --billing-mode PAY_PER_REQUEST \
#      --region us-east-1
#
# 5. Uncomment the configuration below and run:
#    terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     # S3 bucket for storing Terraform state
#     bucket = "my-terraform-state-bucket-<ACCOUNT_ID>"
#
#     # Path within the bucket where this project's state will be stored
#     key = "eks-vpc-cluster/terraform.tfstate"
#
#     # AWS region where the S3 bucket is located
#     region = "us-east-1"
#
#     # DynamoDB table for state locking (prevents concurrent modifications)
#     dynamodb_table = "terraform-state-lock"
#
#     # Enable encryption at rest
#     encrypt = true
#
#     # Optional: Use specific AWS profile
#     # profile = "default"
#
#     # Optional: Add additional tags to the state file
#     # Note: These tags are applied to the S3 object, not the bucket
#   }
# }
#
# Best Practices:
# - Use unique bucket names with account ID to avoid conflicts
# - Enable versioning for state file recovery
# - Use encryption for sensitive data protection
# - Implement state locking with DynamoDB to prevent race conditions
# - Consider using separate state files per environment (dev/staging/prod)
# - Regularly back up your state files
# - Restrict bucket access with IAM policies
#
# Multi-Environment Setup:
# For multiple environments, use workspace-specific keys:
# key = "eks-vpc-cluster/${terraform.workspace}/terraform.tfstate"