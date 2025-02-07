terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      version = "~>3.1"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "myec2" {
  ami = "ami-04681163a08179f28"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  count = 2
  tags = {
    Name = "myinstance ${count.index + 1}"
  }
  key_name = "amazone"
}
resource "aws_security_group" "mysg" {
  name = "my-sg1"
  vpc_id = "vpc-0e3ff6fdb3f5d16ed"
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
}
