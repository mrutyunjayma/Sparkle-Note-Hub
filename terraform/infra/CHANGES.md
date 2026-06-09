# Terraform Infrastructure Changes & Documentation

This document explains the modifications made to the EKS and Secrets Manager infrastructure, the reasons behind these changes, and the technical purpose of each parameter.

---

## 1. AWS Secrets Manager Fix

### File Modified
- [`modules/secrets-manager/main.tf`](file:///home/mj/Sparkle-Note/terraform/infra/modules/secrets-manager/main.tf)

### Changes Made
```hcl
resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  recovery_window_in_days = 0 # <-- Added
}
```

### Why the Change was Made
Previously, running `terraform destroy` or modifying the secrets manager resource would delete the secret in AWS. However, Secrets Manager schedules deleted secrets for a default recovery window of 30 days. When attempting to recreate or run `terraform apply` again with the same secret name, AWS rejected the request with `InvalidRequestException` because the secret name was still reserved.

### Use of the Parameter
- **`recovery_window_in_days = 0`**: Tells AWS Secrets Manager to bypass the recovery window and delete the secret permanently and immediately. This allows subsequent Terraform runs to recreate the secret with the exact same name without waiting 7 to 30 days.

---

## 2. EKS Cluster Endpoint Access

### File Modified
- [`modules/eks_cluster/main.tf`](file:///home/mj/Sparkle-Note/terraform/infra/modules/eks_cluster/main.tf)

### Changes Made
```hcl
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true # <-- Added
    endpoint_public_access  = true # <-- Added
  }
```

### Why the Change was Made
By default, EKS only enables public endpoint access (`endpoint_public_access = true` and `endpoint_private_access = false`). When worker nodes are provisioned in private subnets, they had to route their cluster registration requests through the internet to reach the public EKS API endpoint. 

### Use of the Parameters
- **`endpoint_private_access = true`**: Enables private access to the Amazon EKS Kubernetes API server endpoint. This allows worker nodes inside the VPC's private subnets to communicate directly, securely, and with lower latency to the EKS control plane without sending traffic over the public internet.
- **`endpoint_public_access = true`**: Keeps the public API server endpoint active so that administrative tools (like `kubectl` running on your local development machine) can connect to the EKS cluster.

---

## 3. EKS Addons Configuration

### File Modified
- [`modules/eks_cluster/main.tf`](file:///home/mj/Sparkle-Note/terraform/infra/modules/eks_cluster/main.tf)

### Changes Made
```hcl
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
}
```

### Why the Change was Made
The cluster resource was configured with `bootstrap_self_managed_addons = false`. This instructs EKS *not* to install default add-ons on startup. Because the VPC CNI (`aws-node`) plugin was completely missing, worker nodes could not initialize their network interfaces, causing them to stay in an unhealthy `NotReady` state and causing the EKS Node Group provisioning to time out and fail.

### Use of the Resources
- **`aws_eks_addon.vpc_cni`**: Installs the Amazon VPC CNI plugin, which assigns real VPC private IP addresses to Kubernetes pods, allowing them to communicate.
- **`aws_eks_addon.coredns`**: Installs CoreDNS, which provides standard Kubernetes name resolution (DNS) within the cluster.
- **`aws_eks_addon.kube_proxy`**: Installs kube-proxy, which manages network routing rules on worker nodes to load-balance traffic between pods.

---

## 4. EKS Node Group Subnet Migration

### File Modified
- [`main.tf`](file:///home/mj/Sparkle-Note/terraform/infra/main.tf)

### Changes Made
```hcl
module "eks_node_group" {
  ...
  subnet_ids = module.vpc.private_subnets # <-- Changed from public_subnets
}
```

### Why the Change was Made
Running Kubernetes worker nodes in public subnets exposes them directly to public IPs and potential external threats. 

### Use of the Configuration
- **`private_subnets`**: Deploying nodes in private subnets keeps your worker nodes shielded from direct internet exposure. Outbound internet requests (e.g. pulling Docker images) are routed securely through the VPC NAT Gateways.
