# Codex Changes - 2026-06-15

## Purpose

This note records the Terraform changes made to address two related EKS provisioning issues:

- `coredns` staying in the `DEGRADED` state
- worker nodes failing with `NodeCreationFailure`

## Root Cause

The original Terraform layout created the EKS cluster add-ons as part of the cluster module, before the managed node group was guaranteed to be ready.

That caused a timing issue:

- The EKS control plane was created
- Terraform immediately tried to install `vpc-cni`, `coredns`, and `kube-proxy`
- `coredns` could become stuck in `DEGRADED` because there were no ready worker nodes yet to schedule the pods

## What Changed

### 1. Kept cluster-critical add-ons with the cluster module

File:
- `terraform/infra/modules/eks_cluster/main.tf`

Why:
- Worker nodes need cluster networking components available during bootstrap
- `vpc-cni` and `kube-proxy` should come up with the cluster instead of waiting for the node group
- Delaying all add-ons caused nodes to launch but remain unhealthy

Change made:
- Added these resources in this file:
  - `aws_eks_addon.vpc_cni`
  - `aws_eks_addon.kube_proxy`

### 2. Kept only CoreDNS in the delayed add-ons module

Files:
- `terraform/infra/modules/eks_addons/main.tf`
- `terraform/infra/modules/eks_addons/variables.tf`

Why:
- `coredns` needs schedulable worker nodes
- `coredns` can safely wait until the node group is ready
- `vpc-cni` should not wait for the node group

Change made:
- The delayed add-ons module now manages only:
  - `aws_eks_addon.coredns`
- Added `cluster_name` as an input variable for the new module

### 3. Wired CoreDNS after the node group

File:
- `terraform/infra/main.tf`

Why:
- `coredns` needs available worker nodes to schedule successfully
- Explicit dependency on the node group removes the scheduling race condition without delaying cluster networking add-ons

Change made:
- Added:

```hcl
module "eks_addons" {
  source = "./modules/eks_addons"

  cluster_name = module.eks_cluster.cluster_name

  depends_on = [module.eks_node_group]
}
```

- This ensures the apply order is:
  1. EKS cluster
  2. `vpc-cni` and `kube-proxy`
  3. Managed node group
  4. `coredns`

## Files Modified

- `terraform/infra/main.tf`
- `terraform/infra/modules/eks_cluster/main.tf`

## Files Added

- `terraform/infra/modules/eks_addons/main.tf`
- `terraform/infra/modules/eks_addons/variables.tf`
- `CODEX_CHANGES_2026-06-15.md`

## Validation Notes

- `terraform fmt` was run on the changed Terraform files
- `terraform validate` reported `Module not installed` until `terraform init` is run again, which is expected after adding a new module

## Next Step

Run:

```bash
cd terraform/infra
terraform init
terraform apply
```

If `coredns` still remains `DEGRADED` after this, the next checks should be:

- whether node group instances joined the cluster
- whether worker node IAM permissions are correct
- whether subnet/NAT routing allows pulling required images
- whether the worker subnets have enough free IP addresses
