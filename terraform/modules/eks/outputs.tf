output "cluster_id" {
  description = "The ID of the EKS cluster. Note: currently a value is returned only for local EKS clusters created on Outposts"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.main.status
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = try(aws_security_group.cluster[0].arn, null)
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, null)
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_tls_certificate_sha1_fingerprint" {
  description = "The SHA1 fingerprint of the public key of the for the EKS cluster's certificate"
  value       = try(data.tls_certificate.eks[0].certificates[0].sha1_fingerprint, null)
}

output "cluster_token" {
  description = "The token to use to authenticate with the cluster"
  value       = try(data.aws_eks_cluster_auth.main[0].token, null)
  sensitive   = true
}

output "cluster_service_cidr" {
  description = "The CIDR block where Kubernetes services are assigned IP addresses from"
  value       = try(aws_eks_cluster.main.kubernetes_network_config[0].service_ipv4_cidr, null)
}

output "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses"
  value       = try(aws_eks_cluster.main.kubernetes_network_config[0].ip_family, null)
}

# IAM Role outputs
output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = aws_iam_role.eks_cluster.unique_id
}

# OIDC Identity provider
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Identity Provider if enabled"
  value       = try(aws_iam_openid_connect_provider.eks[0].arn, null)
}

output "oidc_provider_url" {
  description = "The URL of the identity provider. Corresponds to the iss claim"
  value       = try(aws_iam_openid_connect_provider.eks[0].url, null)
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

# Node Groups
output "node_groups" {
  description = "Map of attribute maps for all EKS node groups created"
  value       = aws_eks_node_group.main
  sensitive   = true
}

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      node_group_name     = v.node_group_name
      node_group_arn      = v.arn
      node_group_status   = v.status
      capacity_type       = v.capacity_type
      instance_types      = v.instance_types
      ami_type           = v.ami_type
      node_role_arn      = v.node_role_arn
      subnet_ids         = v.subnet_ids
      remote_access      = v.remote_access
      scaling_config     = v.scaling_config
      update_config      = v.update_config
      version            = v.version
      labels             = v.labels
      taints             = v.taint
      disk_size          = v.disk_size
      release_version    = v.release_version
      resources          = v.resources
    }
  }
}

output "node_groups_iam_role_name" {
  description = "IAM role name associated with EKS node groups"
  value       = aws_iam_role.eks_node_group.name
}

output "node_groups_iam_role_arn" {
  description = "IAM role ARN associated with EKS node groups"
  value       = aws_iam_role.eks_node_group.arn
}

output "node_groups_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = aws_iam_role.eks_node_group.unique_id
}

# EKS Addons
output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value = {
    for k, v in aws_eks_addon.main : k => {
      addon_name               = v.addon_name
      addon_version            = v.addon_version
      arn                     = v.arn
      created_at              = v.created_at
      modified_at             = v.modified_at
      service_account_role_arn = v.service_account_role_arn
      status                  = v.status
    }
  }
}

# Kubeconfig
output "kubeconfig" {
  description = "kubectl config as generated by the module"
  value = {
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    contexts = [{
      name = "terraform"
      context = {
        cluster = "terraform"
        user    = "terraform"
      }
    }]
    clusters = [{
      name = "terraform"
      cluster = {
        certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
        server                     = aws_eks_cluster.main.endpoint
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = try(data.aws_eks_cluster_auth.main[0].token, null)
      }
    }]
  }
  sensitive = true
}

# Convenience outputs
output "configure_kubectl" {
  description = "Command to configure kubectl to connect to the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}

output "cluster_region" {
  description = "AWS region where the cluster is deployed"
  value       = data.aws_region.current.name
}

# Network configuration
output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "List of subnet IDs where the cluster is deployed"
  value       = var.subnet_ids
}

output "cluster_vpc_config" {
  description = "The cluster VPC configuration"
  value = {
    cluster_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
    endpoint_private_access   = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
    endpoint_public_access    = aws_eks_cluster.main.vpc_config[0].endpoint_public_access
    public_access_cidrs       = aws_eks_cluster.main.vpc_config[0].public_access_cidrs
    security_group_ids        = aws_eks_cluster.main.vpc_config[0].security_group_ids
    subnet_ids               = aws_eks_cluster.main.vpc_config[0].subnet_ids
    vpc_id                   = aws_eks_cluster.main.vpc_config[0].vpc_id
  }
}