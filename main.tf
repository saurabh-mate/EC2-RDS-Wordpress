terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "aws_instance" "wordpress_server" {
  ami           = "ami-00bb6a80f01f03502"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.TF_SG.id]
  key_name = "tf-key"

  root_block_device {
    volume_type = "gp3"
    volume_size = 12
  }

  tags = {
    Name = "My-Instance"
  }
}
resource "aws_db_instance" "wordpress_rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.40"
  instance_class       = "db.t3.micro"
  username             = "saurabh"
  password             = "saurabh123"
  publicly_accessible  = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  
  db_name              = "wordpress"  

  tags = {
    Name = "wordPress"
  }
}

resource "aws_security_group" "TF_SG" {
  name        = "security group using terraform"
  description = "security group using terraform"
  vpc_id      = "vpc-00e44613fd15c9ec2"

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "My-server"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL traffic from EC2"
  vpc_id      = "vpc-00e44613fd15c9ec2"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.TF_SG.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS-SG"
  }
}

resource "local_file" "inventory" {
  filename = "ansible/inventory.ini"
  content  = <<-EOT
    [server]
    ${aws_instance.wordpress_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/saurabh/Downloads/tf-key.pem
  EOT
}

resource "cloudflare_record" "terraform_subdomain" {
  zone_id = var.cloudflare_zone_id
  name    = "wordpress"
  value   = aws_instance.wordpress_server.public_ip
  type    = "A"
  ttl     = 1
  proxied = true
}

output "instance_public_ip" {
  value = aws_instance.wordpress_server.public_ip
}
output "rds_endpoint" {
  value = aws_db_instance.wordpress_rds.endpoint
  description = "The endpoint of the RDS instance"
}

output "subdomain_url" {
  value = "http://wordpress.purvesh.cloud"
}
