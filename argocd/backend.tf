terraform {
  backend "s3" {
    bucket = "terraform-state-mlops-argocd-2200221113847445824"  # Унікальна назва з Account ID
    key    = "argocd/terraform.tfstate"
    region = "us-east-1"
    
    # Uncomment and configure if using DynamoDB for state locking
    # dynamodb_table = "terraform-locks"
  }
}
