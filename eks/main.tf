
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = var.private_subnets
  vpc_id          = var.vpc_id

  # Cluster endpoint access configuration
  cluster_endpoint_private_access      = var.enable_cluster_private_access
  cluster_endpoint_public_access       = var.enable_cluster_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_public_access_cidrs

  # KMS encryption for EKS secrets (best practice for production)
  cluster_encryption_config = var.kms_key_arn != null ? {
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  } : {}

  # Enable control plane logging (critical for production monitoring)
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    # CPU workload node group
    cpu_nodes = {
      name            = "${var.cluster_name}-cpu-nodes"
      description     = "EKS managed node group for CPU workloads"
      use_name_prefix = true

      # Capacity configuration
      desired_size = var.cpu_desired_capacity
      max_size     = var.cpu_max_capacity
      min_size     = var.cpu_min_capacity

      # Instance configuration
      instance_types = var.cpu_instance_types
      capacity_type  = "ON_DEMAND"
      ami_type       = var.cpu_ami_type

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.cpu_disk_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Metadata options - enforce IMDSv2 for better security
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
        instance_metadata_tags      = "disabled"
      }

      # Labels for workload scheduling
      labels = {
        workload-type = "cpu"
        node-type     = "standard"
      }

      # Taints - none for general CPU workloads
      taints = []

      # Update configuration
      update_config = {
        max_unavailable_percentage = 33
      }
    }

    # GPU workload node group
    gpu_nodes = {
      name            = "${var.cluster_name}-gpu-nodes"
      description     = "EKS managed node group for GPU workloads"
      use_name_prefix = true

      # Capacity configuration
      desired_size = var.gpu_desired_capacity
      max_size     = var.gpu_max_capacity
      min_size     = var.gpu_min_capacity

      # CRITICAL FIX: Use actual GPU instances (not t3.small!)
      instance_types = var.gpu_instance_types
      capacity_type  = "ON_DEMAND"
      ami_type       = var.gpu_ami_type

      # Disk configuration - GPUs typically need more storage
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.gpu_disk_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Metadata options - enforce IMDSv2
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
        instance_metadata_tags      = "disabled"
      }

      # Labels for GPU workload scheduling
      labels = {
        workload-type   = "gpu"
        node-type       = "gpu-accelerated"
        nvidia.com/gpu  = "true"
      }

      # Taints to ensure only GPU workloads run on these expensive nodes
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]

      # Update configuration
      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }

  # Cluster add-ons (essential for cluster functionality)
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # EBS CSI Driver for persistent volume support
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  tags = var.tags
}

resource "aws_eks_access_entry" "cluster_admin" {
  count         = length(var.cluster_admin_users)
  cluster_name  = module.eks.cluster_name
  principal_arn = var.cluster_admin_users[count.index]
  type         = "STANDARD"

  depends_on = [module.eks]
}

# Associate cluster admin policy
resource "aws_eks_access_policy_association" "cluster_admin" {
  count         = length(var.cluster_admin_users)
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.cluster_admin_users[count.index]

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}
