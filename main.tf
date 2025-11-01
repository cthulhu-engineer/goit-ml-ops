# ========================================
# Provider Configuration
# ========================================

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = local.common_tags
  }
}

# ========================================
# VPC Module
# ========================================

module "vpc" {
  source = "./vpc"

  # VPC Configuration
  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  database_subnets   = var.database_subnets

  # VPC Flow Logs
  enable_vpc_flow_logs   = var.enable_vpc_flow_logs
  flow_log_retention_days = var.flow_log_retention_days

  # EKS-required subnet tags
  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags

  # Tags
  tags = local.common_tags
}

# ========================================
# EKS Module
# ========================================

module "eks" {
  source = "./eks"

  # Dependencies
  depends_on = [module.vpc]

  # Cluster Configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  # Cluster Access
  enable_cluster_private_access    = var.enable_cluster_private_access
  enable_cluster_public_access     = var.enable_cluster_public_access
  cluster_public_access_cidrs      = var.cluster_public_access_cidrs
  cluster_admin_users              = var.cluster_admin_users

  # Security
  kms_key_arn               = var.kms_key_arn
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # CPU Node Group
  cpu_instance_types   = var.cpu_instance_types
  cpu_ami_type         = var.cpu_ami_type
  cpu_disk_size        = var.cpu_disk_size
  cpu_desired_capacity = var.cpu_desired_capacity
  cpu_min_capacity     = var.cpu_min_capacity
  cpu_max_capacity     = var.cpu_max_capacity

  # GPU Node Group
  gpu_instance_types   = var.gpu_instance_types
  gpu_ami_type         = var.gpu_ami_type
  gpu_disk_size        = var.gpu_disk_size
  gpu_desired_capacity = var.gpu_desired_capacity
  gpu_min_capacity     = var.gpu_min_capacity
  gpu_max_capacity     = var.gpu_max_capacity

  # Tags
  tags = local.common_tags
}