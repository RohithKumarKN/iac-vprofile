# Launch Template using AL2023 AMI
resource "aws_launch_template" "eks_al2023_lt" {
  name_prefix   = "eks-al2023-"
  image_id      = "ami-0003dcf2aa06ea5c8" # AL2023 AMI for Kubernetes 1.34 in ap-south-1
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