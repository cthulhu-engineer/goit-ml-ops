# ========================================
# Cluster Configuration
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

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the EKS cluster and nodes"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

# ========================================
# Cluster Access Configuration
# ========================================

variable "enable_cluster_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "enable_cluster_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API endpoint. WARNING: Use specific IPs in production!"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_users" {
  description = "List of IAM user ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}

# ========================================
# Security Configuration
# ========================================

variable "kms_key_arn" {
  description = "ARN of KMS key for EKS secrets encryption. Leave null to use AWS managed key."
  type        = string
  default     = null
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
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
  description = "AMI type for CPU nodes. Valid values: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64"
  type        = string
  default     = "AL2_x86_64"
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

  validation {
    condition     = var.cpu_desired_capacity >= 0
    error_message = "CPU desired capacity must be >= 0."
  }
}

variable "cpu_min_capacity" {
  description = "Minimum number of CPU nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.cpu_min_capacity >= 0
    error_message = "CPU minimum capacity must be >= 0."
  }
}

variable "cpu_max_capacity" {
  description = "Maximum number of CPU nodes"
  type        = number
  default     = 4

  validation {
    condition     = var.cpu_max_capacity >= 1
    error_message = "CPU maximum capacity must be >= 1."
  }
}

# ========================================
# GPU Node Group Configuration
# ========================================

variable "gpu_instance_types" {
  description = "List of GPU instance types. Common: g4dn.xlarge, g4dn.2xlarge, p3.2xlarge"
  type        = list(string)
  default     = ["g4dn.xlarge"]
}

variable "gpu_ami_type" {
  description = "AMI type for GPU nodes. Use AL2_x86_64_GPU for NVIDIA GPUs"
  type        = string
  default     = "AL2_x86_64_GPU"
}

variable "gpu_disk_size" {
  description = "Disk size in GB for GPU nodes (usually needs more than CPU)"
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

  validation {
    condition     = var.gpu_desired_capacity >= 0
    error_message = "GPU desired capacity must be >= 0."
  }
}

variable "gpu_min_capacity" {
  description = "Minimum number of GPU nodes"
  type        = number
  default     = 0

  validation {
    condition     = var.gpu_min_capacity >= 0
    error_message = "GPU minimum capacity must be >= 0."
  }
}

variable "gpu_max_capacity" {
  description = "Maximum number of GPU nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.gpu_max_capacity >= 0
    error_message = "GPU maximum capacity must be >= 0."
  }
}

# ========================================
# Common Configuration
# ========================================

variable "tags" {
  description = "Common tags to apply to all EKS resources"
  type        = map(string)
  default     = {}
}