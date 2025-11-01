module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  database_subnets     = var.database_subnets

  # High availability: one NAT gateway per AZ
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # DNS
  enable_dns_support   = true
  enable_dns_hostnames = true

  # VPC Flow Logs for network monitoring and security
  enable_flow_log                      = var.enable_vpc_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_vpc_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_vpc_flow_logs
  flow_log_retention_in_days           = var.flow_log_retention_days

  # EKS requires specific tags on subnets for Load Balancer discovery
  public_subnet_tags = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags

  # Database subnet configuration
  create_database_subnet_group = length(var.database_subnets) > 0

  tags = var.tags
}