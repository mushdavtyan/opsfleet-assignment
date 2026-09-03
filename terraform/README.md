# EKS + Karpenter (Graviton & Spot)

Terraform that stands up a dedicated VPC, an EKS `1.36` cluster, and Karpenter `1.14.1` with NodePools for **x86** and **Graviton (arm64)**. Both pools prefer Spot and fall back to on-demand. A small on-demand Graviton managed node group runs Karpenter and cluster add-ons only.

```text
Developer laptop
       │  kubectl
       ▼
  EKS control plane (1.36)
       │
       ├── Managed node group (m6g.large, on-demand, CriticalAddonsOnly)
       │     └── Karpenter controller
       │
       └── Karpenter NodePools
             ├── graviton  (arm64, Spot preferred, weight 50)
             └── x86       (amd64, Spot preferred, weight 10)
```

## Prerequisites

- Terraform >= 1.5.7
- AWS CLI v2, with credentials that can create VPC, EKS, IAM, and EC2 resources
- `kubectl`
- Helm 3 (used by the Terraform Helm provider)

```bash
aws sts get-caller-identity
```

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit region / cluster_name as needed
terraform init
terraform plan
terraform apply
```

First apply typically takes 15–20 minutes (VPC, NAT, EKS control plane, node group, Karpenter).

Point `kubectl` at the cluster:

```bash
$(terraform output -raw configure_kubectl)
```

Confirm Karpenter and the NodePools:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter
kubectl get nodepools
kubectl get ec2nodeclass
```

## Run a workload on x86 or Graviton

Karpenter provisions a node only when pods are unschedulable. Architecture is selected with the standard Kubernetes label `kubernetes.io/arch`. Example images are multi-arch (`nginx` from ECR Public).

**x86 (amd64)**

```bash
kubectl apply -f examples/deploy-x86.yaml
kubectl get pods -l app=demo-x86 -o wide
kubectl get nodes -l kubernetes.io/arch=amd64 \
  -L kubernetes.io/arch,karpenter.sh/capacity-type,karpenter.sh/nodepool
```

**Graviton (arm64)**

```bash
kubectl apply -f examples/deploy-graviton.yaml
kubectl get pods -l app=demo-graviton -o wide
kubectl get nodes -l kubernetes.io/arch=arm64 \
  -L kubernetes.io/arch,karpenter.sh/capacity-type,karpenter.sh/nodepool
```

New nodes should show `karpenter.sh/nodepool=x86` or `graviton`, and `karpenter.sh/capacity-type=spot` when Spot capacity is available.

The same pin in any Deployment:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64   # or arm64 for Graviton
```

Pods that omit the selector can land on either pool; the Graviton pool has a higher Karpenter weight, so unconstrained work prefers arm64.

Watch provisioning live:

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f
kubectl get nodeclaims -w
```

## Tear down

Delete sample workloads first so Karpenter can terminate the nodes it created, then destroy the stack. Helm is uninstalled before the VPC so NodePool / EC2NodeClass finalizers can still reach AWS through NAT.

```bash
kubectl delete -f examples/deploy-x86.yaml --ignore-not-found
kubectl delete -f examples/deploy-graviton.yaml --ignore-not-found
# Optional: wait until Karpenter nodes are gone
kubectl get nodes -l karpenter.sh/registered
terraform destroy
```

Leaving the cluster running incurs cost (EKS control plane, NAT Gateway, and the two managed nodes, plus any Spot/on-demand nodes Karpenter launched).

## Layout

| Path | Purpose |
| --- | --- |
| `vpc.tf` | Dedicated VPC, 3 AZs, public / private / intra subnets, NAT |
| `eks.tf` | EKS 1.36, add-ons, Graviton managed node group |
| `karpenter.tf` | IAM, Pod Identity, Spot interruption queue, Helm install |
| `nodepools.tf` / `charts/karpenter-nodes/` | EC2NodeClass + `x86` / `graviton` NodePools |
| `examples/` | Developer demo Deployments |

Remote state is left local for the POC. Use an S3 backend before sharing this with a team.

## AWS credentials

Terraform uses the standard AWS credential chain. This repo does not store keys.
