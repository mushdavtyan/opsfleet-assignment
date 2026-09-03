resource "helm_release" "karpenter_nodes" {
  name             = "karpenter-nodes"
  namespace        = "kube-system"
  create_namespace = false
  chart            = "${path.module}/charts/karpenter-nodes"
  wait             = true
  atomic           = true
  timeout          = 600

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      nodeRole    = module.karpenter.node_iam_role_name
    }),
  ]

  depends_on = [
    helm_release.karpenter,
    module.vpc,
  ]
}
