data "aws_iam_roles" "ec2_spot" {
  name_regex = "^AWSServiceRoleForEC2Spot$"
}

# Only create the Spot SLR when this account has never used Spot.
resource "aws_iam_service_linked_role" "spot" {
  count = length(data.aws_iam_roles.ec2_spot.names) == 0 ? 1 : 0

  aws_service_name = "spot.amazonaws.com"
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.25"

  cluster_name = module.eks.cluster_name

  # Stable role name referenced by EC2NodeClass.spec.role.
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = "${var.cluster_name}-karpenter-node"
  create_pod_identity_association = true
  enable_spot_termination         = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = "kube-system"
  create_namespace = false
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version
  wait             = true
  atomic           = true
  timeout          = 600

  values = [
    yamlencode({
      dnsPolicy = "Default"
      serviceAccount = {
        name = "karpenter"
      }
      nodeSelector = {
        "kubernetes.io/os"        = "linux"
        "karpenter.sh/controller" = "true"
      }
      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
      ]
      settings = {
        clusterName       = module.eks.cluster_name
        clusterEndpoint   = module.eks.cluster_endpoint
        interruptionQueue = module.karpenter.queue_name
        eksControlPlane   = true
        enableZonalShift  = false
      }
      controller = {
        resources = {
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }
    }),
  ]

  depends_on = [
    module.eks,
    module.karpenter,
    module.vpc,
  ]
}
