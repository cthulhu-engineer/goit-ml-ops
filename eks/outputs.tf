
# ========================================
# Cluster Information
# ========================================

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "eks_cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "eks_cluster_status" {
  description = "Status of the EKS cluster. One of CREATING, ACTIVE, DELETING, FAILED"
  value       = module.eks.cluster_status
}

# ========================================
# Security & Access
# ========================================

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

# ========================================
# OIDC Provider (for IRSA - IAM Roles for Service Accounts)
# ========================================

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS (used for IRSA)"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider" {
  description = "The OIDC Identity Provider (without https://)"
  value       = module.eks.oidc_provider
}

# ========================================
# IAM Roles
# ========================================

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "eks_cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

# ========================================
# Node Groups
# ========================================

output "eks_managed_node_groups" {
  description = "Map of managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of autoscaling group names for managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}