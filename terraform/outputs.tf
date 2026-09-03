output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the control plane."
  value       = module.eks.cluster_version
}

output "configure_kubectl" {
  description = "Command to update kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "Dedicated VPC ID."
  value       = module.vpc.vpc_id
}

output "karpenter_node_iam_role_name" {
  description = "IAM role name referenced by the Karpenter EC2NodeClass."
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_interruption_queue" {
  description = "SQS queue Karpenter uses for Spot interruption handling."
  value       = module.karpenter.queue_name
}

output "region" {
  description = "AWS region of the cluster."
  value       = var.region
}
