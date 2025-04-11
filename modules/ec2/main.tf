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

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.sg_id]
  }

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update packages
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $$(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$${VERSION_CODENAME}}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl enable docker
    systemctl start docker
    
    # Run Docker container
    docker pull nginx:latest
    docker run -d -p 80:80 --name my-web-app nginx:latest
    
    # Create directory if it doesn't exist
    mkdir -p /var/www/html
    
    # Write health check file
    echo "Docker container running" > /var/www/html/index.html
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}