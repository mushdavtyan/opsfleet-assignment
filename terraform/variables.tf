variable "region" {
  description = "AWS region for the dedicated VPC and EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name used for the EKS cluster, VPC, and Karpenter discovery tags."
  type        = string
  default     = "eks-karpenter"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name)) && length(var.cluster_name) <= 100
    error_message = "cluster_name must start with a letter, contain only alphanumeric characters and hyphens, and be at most 100 characters."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Defaults to the latest generally available version on EKS (1.36 as of August 2026)."
  type        = string
  default     = "1.36"
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version. 1.14.x is the current stable line and supports Kubernetes 1.36."
  type        = string
  default     = "1.14.1"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint. Restrict this in any shared environment."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "profile" {
  description = "Optional AWS shared-config profile. Leave unset to use the default credential chain."
  type        = string
  default     = null
}

variable "access_key" {
  description = "Optional AWS access key. Prefer AWS_ACCESS_KEY_ID in the environment."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key" {
  description = "Optional AWS secret key. Prefer AWS_SECRET_ACCESS_KEY in the environment."
  type        = string
  default     = null
  sensitive   = true
}

variable "token" {
  description = "Optional AWS session token for temporary credentials."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
