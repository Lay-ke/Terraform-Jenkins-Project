provider "aws" {
  region = "us-east-1"
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
    { cidr = "192.168.16.0/24", az = "us-east-1a", name = "PublicSubnet1" },
    { cidr = "192.168.32.0/20", az = "us-east-1b", name = "PublicSubnet2" },
    { cidr = "192.168.48.0/20", az = "us-east-1c", name = "PublicSubnet3" }
  ]

  private_subnets = [
    { cidr = "192.168.64.0/20", az = "us-east-1a", name = "PrivateSubnet1" },
    { cidr = "192.168.80.0/20", az = "us-east-1b", name = "PrivateSubnet2" }
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
  iam_instance_profile_name = "EC2InstanceProfile"
}

# Auto Scaling Group for EC2 instances using Launch Template
resource "aws_autoscaling_group" "this" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = module.subnets.private_subnet_ids
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
    value               = "LampAutoScalingGroup"
    propagate_at_launch = true
  }
}
