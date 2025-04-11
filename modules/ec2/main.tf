resource "aws_iam_role" "instance_role" {
  name = "instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_launch_template" "this" {
  name_prefix   = "lamp-launch-template-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  security_group_names = [var.sg_id]
  
  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World!" > /var/www/html/index.html
              EOF

  lifecycle {
    create_before_destroy = true
  }
}