terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      version = "~>3.1"
    }
  }
}
provider "aws" {
  region = var.my_region
  access_key = var.access_key
  secret_key = var.secret_key
}
resource "aws_instance" "myec2" {

  ami           = var.ami_id
  instance_type =lookup(var.ins_type,terraform.workspace)
  tags = {
    Name = "myinstance"
  }
}
