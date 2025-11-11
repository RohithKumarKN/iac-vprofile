terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }

  backend "s3" {
    bucket           = "app-deployment-rohith"
    key              = "terraform.tfstate"
    region           = "ap-south-1"
    state_lock_table = "terraform-lock-table-rohith"
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_launch_template" "eks_al2023_lt" {
  name_prefix   = "eks-al2023-"
  image_id      = "ami-0003dcf2aa06ea5c8"  # AL2023 AMI for Kubernetes 1.34 in ap-south-1
  instance_type = "t3.small"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "eks-al2023-node"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.34"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    one = {
      name           = "node-group-1"
      instance_types = ["t3.small"]
      launch_template = {
        name    = aws_launch_template.eks_al2023_lt.name
        version = "$Latest"
      }
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name           = "node-group-2"
      instance_types = ["t3.small"]
      launch_template = {
        name    = aws_launch_template.eks_al2023_lt.name
        version = "$Latest"
      }
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

locals {
  cluster_name = var.clusterName
} 
