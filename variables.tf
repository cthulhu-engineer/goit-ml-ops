# ========================================
# AWS Provider Configuration
# ========================================

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region (e.g., us-east-1, eu-west-1)."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile name for authentication"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "terraform"
    Environment = "development"
  }
}

# ========================================
# VPC Configuration
# ========================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones. Leave empty to use all available AZs in the region."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring and security analysis"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "Flow log retention must be a valid CloudWatch Logs retention value."
  }
}

# ========================================
# EKS Cluster Configuration
# ========================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) <= 100 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter, contain only alphanumeric characters and hyphens, and be <= 100 characters."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"

  validation {
    condition     = can(regex("^1\\.(2[789]|3[01])$", var.cluster_version))
    error_message = "Cluster version must be a valid Kubernetes version (1.27-1.31)."
  }
}

# ========================================
# EKS Cluster Access Configuration
# ========================================

variable "enable_cluster_private_access" {
  description = "Enable private API server endpoint (recommended for production)"
  type        = bool
  default     = true
}

variable "enable_cluster_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API endpoint. WARNING: Use specific IPs in production, not 0.0.0.0/0!"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_users" {
  description = "List of IAM user ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}

# ========================================
# EKS Security Configuration
# ========================================

variable "kms_key_arn" {
  description = "ARN of KMS key for EKS secrets encryption. Leave null to use AWS managed key."
  type        = string
  default     = null
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable. Valid: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_enabled_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Log types must be one of: api, audit, authenticator, controllerManager, scheduler."
  }
}

# ========================================
# CPU Node Group Configuration
# ========================================

variable "cpu_instance_types" {
  description = "List of instance types for CPU node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "cpu_ami_type" {
  description = "AMI type for CPU nodes. Valid: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64"
  type        = string
  default     = "AL2_x86_64"

  validation {
    condition     = contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64"], var.cpu_ami_type)
    error_message = "CPU AMI type must be a valid EKS AMI type."
  }
}

variable "cpu_disk_size" {
  description = "Disk size in GB for CPU nodes"
  type        = number
  default     = 50

  validation {
    condition     = var.cpu_disk_size >= 20 && var.cpu_disk_size <= 16384
    error_message = "CPU disk size must be between 20 and 16384 GB."
  }
}

variable "cpu_desired_capacity" {
  description = "Desired number of CPU nodes"
  type        = number
  default     = 2
}

variable "cpu_min_capacity" {
  description = "Minimum number of CPU nodes"
  type        = number
  default     = 1
}

variable "cpu_max_capacity" {
  description = "Maximum number of CPU nodes"
  type        = number
  default     = 4
}

# ========================================
# GPU Node Group Configuration
# ========================================

variable "gpu_instance_types" {
  description = "List of GPU instance types. Common: g4dn.xlarge, g4dn.2xlarge, p3.2xlarge, p4d.24xlarge"
  type        = list(string)
  default     = ["g4dn.xlarge"]
}

variable "gpu_ami_type" {
  description = "AMI type for GPU nodes. Use AL2_x86_64_GPU for NVIDIA GPUs"
  type        = string
  default     = "AL2_x86_64_GPU"

  validation {
    condition     = contains(["AL2_x86_64_GPU", "BOTTLEROCKET_x86_64_NVIDIA"], var.gpu_ami_type)
    error_message = "GPU AMI type must support GPU workloads."
  }
}

variable "gpu_disk_size" {
  description = "Disk size in GB for GPU nodes (usually needs more storage than CPU)"
  type        = number
  default     = 100

  validation {
    condition     = var.gpu_disk_size >= 20 && var.gpu_disk_size <= 16384
    error_message = "GPU disk size must be between 20 and 16384 GB."
  }
}

variable "gpu_desired_capacity" {
  description = "Desired number of GPU nodes (set to 0 to save costs when not needed)"
  type        = number
  default     = 0
}

variable "gpu_min_capacity" {
  description = "Minimum number of GPU nodes"
  type        = number
  default     = 0
}

variable "gpu_max_capacity" {
  description = "Maximum number of GPU nodes"
  type        = number
  default     = 2
}