terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    # Configure these values in terraform init or backend config file
    # bucket         = "your-terraform-state-bucket"
    # key            = "eks-infrastructure/terraform.tfstate"
    # region         = "us-west-2"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  
  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  project_name             = var.project_name
  environment              = var.environment
  cluster_name             = local.cluster_name
  cluster_version          = var.cluster_version
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  control_plane_subnet_ids = module.vpc.public_subnet_ids
  
  # Node groups configuration
  node_groups = var.node_groups
  
  # Security groups
  additional_security_group_ids = [
    module.security.eks_additional_security_group_id
  ]
  
  # OIDC provider
  enable_irsa = var.enable_irsa
  
  # Logging
  cluster_enabled_log_types = var.cluster_enabled_log_types
  
  # Add-ons
  cluster_addons = var.cluster_addons
  
  tags = local.common_tags
  
  depends_on = [module.vpc, module.security]
}