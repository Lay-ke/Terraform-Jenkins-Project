provider "aws" {
  region = "eu-west-1"
}

# Module for VPC
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "192.168.0.0/16"
  name       = "LAMP-VPC"
}

# Module for Subnets
module "subnets" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id

  public_subnets = [
    { cidr = "192.168.16.0/24", az = "eu-west-1a", name = "PublicSubnet1" },
    { cidr = "192.168.32.0/20", az = "eu-west-1b", name = "PublicSubnet2" },
    { cidr = "192.168.48.0/20", az = "eu-west-1c", name = "PublicSubnet3" }
  ]

  private_subnets = [
    { cidr = "192.168.64.0/20", az = "eu-west-1a", name = "PrivateSubnet1" },
    { cidr = "192.168.80.0/20", az = "eu-west-1b", name = "PrivateSubnet2" }
  ]
}

# Module for Security Groups
module "security_groups" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id
}

# Module for Application Load Balancer (ALB)
module "alb" {
  source     = "./modules/alb"
  name       = "LAMP-ALB"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnets.public_subnet_ids
  sg_id      = module.security_groups.lb_sg_id
}

# Module for EC2 instances behind the Load Balancer
module "ec2" {
  source                    = "./modules/ec2"
  instance_type             = "t2.micro"
  sg_id                     = module.security_groups.web_sg_id
  iam_instance_profile_name = "instance-profile"
  ami_id = "ami-0df368112825f8d8f"
}

# Auto Scaling Group for EC2 instances using Launch Template
resource "aws_autoscaling_group" "this" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = module.subnets.public_subnet_ids
  launch_template {
    id      = module.ec2.launch_template_id
    version = "$Latest"
  }
  target_group_arns = [module.alb.target_group_arn]  # To access the tg_arn I had to output it in the alb module

  health_check_type         = "EC2"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "0"
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "WebServer"
    propagate_at_launch = true
  }
}

module "iam" {
  source = "./modules/iam"
  
  cluster_name             = var.cluster_name
  enable_cluster_autoscaler = false
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name           = var.cluster_name
  cluster_role_arn       = module.iam.eks_cluster_role_arn
  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  
  # Reference existing subnets instead of creating new ones
  subnet_ids             = module.subnets.private_subnet_ids
  
  # Pass existing security groups
  security_group_ids     = [module.security_groups.web_sg_id] # List of security groups
  
  # Don't create a new security group in the EKS module
  create_cluster_security_group = false
  
  tags                   = var.tags
  
  cluster_dependencies = [
    module.iam.eks_cluster_role_arn
  ]
}


module "node_groups" {
  source = "./modules/node_groups"
  
  cluster_name    = module.eks.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = module.iam.eks_node_role_arn
  
  # Use existing private subnets
  subnet_ids      = module.subnets.private_subnet_ids
  
  instance_types  = var.node_instance_types
  desired_size    = var.node_desired_size
  min_size        = var.node_min_size
  max_size        = var.node_max_size
  tags            = var.tags
  
  # You might want to add your security group here
  source_security_group_ids = [module.security_groups.web_sg_id]
  
  node_group_dependencies = [
    module.iam.eks_node_role_arn
  ]
}

