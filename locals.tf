# Local values for computed or repeated values
locals {
  # Common naming prefix
  name_prefix = "${var.cluster_name}-${var.region}"

  # Common tags that will be applied to all resources
  common_tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = lookup(var.tags, "Environment", "development")
      ClusterName = var.cluster_name
    }
  )

  # EKS cluster tags for VPC resources
  # These tags are required for EKS to discover subnets for Load Balancers
  eks_cluster_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  # Public subnet specific tags (for external load balancers)
  public_subnet_tags = merge(
    local.eks_cluster_tags,
    {
      "kubernetes.io/role/elb" = "1"
      Tier                     = "public"
    }
  )

  # Private subnet specific tags (for internal load balancers)
  private_subnet_tags = merge(
    local.eks_cluster_tags,
    {
      "kubernetes.io/role/internal-elb" = "1"
      Tier                              = "private"
    }
  )
}
