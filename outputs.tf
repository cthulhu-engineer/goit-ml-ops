# ========================================
# VPC Outputs
# ========================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

# ========================================
# EKS Cluster Outputs
# ========================================

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.eks_cluster_id
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.eks_cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.eks_cluster_version
}

output "eks_cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.eks_cluster_status
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.eks_cluster_certificate_authority_data
  sensitive   = true
}

# ========================================
# EKS Security Outputs
# ========================================

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.eks_cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.eks_node_security_group_id
}

# ========================================
# EKS OIDC Provider Outputs (for IRSA)
# ========================================

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS (required for IAM Roles for Service Accounts)"
  value       = module.eks.eks_oidc_provider_arn
}

output "eks_oidc_provider" {
  description = "The OIDC Identity Provider (without https://)"
  value       = module.eks.eks_oidc_provider
}

# ========================================
# EKS IAM Role Outputs
# ========================================

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.eks_cluster_iam_role_arn
}

output "eks_cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.eks.eks_cluster_iam_role_name
}

# ========================================
# EKS Node Groups Outputs
# ========================================

output "eks_managed_node_groups" {
  description = "Map of managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of autoscaling group names for managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

# ========================================
# Helper Commands
# ========================================

output "kubectl_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.eks_cluster_name}"
}

output "eks_console_url" {
  description = "AWS Console URL for the EKS cluster"
  value       = "https://console.aws.amazon.com/eks/home?region=${var.region}#/clusters/${module.eks.eks_cluster_name}"
}
