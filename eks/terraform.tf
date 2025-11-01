terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {
    bucket = "terraform-state-mlops-argocd-2200221113847445824"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}
