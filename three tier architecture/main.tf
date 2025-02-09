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
resource "aws_vpc" "custom-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "myvpc"
  }
}
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.custom-vpc.id
  tags = {
    Name = "myigw"
  }
}
resource "aws_subnet" "websubnet" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "websubnet"
  }
}
resource "aws_subnet" "appsubnet" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "appsubnet"
  }
}
resource "aws_subnet" "dbsubnet" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "dbsubnet"
  }
}
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.custom-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  tags = {
    Name = "public-rt"
  }
}
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.custom-vpc.id
  tags = {
    Name = "private-rt"
  }
}
resource "aws_route_table_association" "web-assoc" {
  subnet_id      = aws_subnet.websubnet.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "app-assoc" {
  subnet_id      = aws_subnet.appsubnet.id
  route_table_id = aws_route_table.private-rt.id
}
resource "aws_route_table_association" "db-assoc" {
  subnet_id      = aws_subnet.dbsubnet.id
  route_table_id = aws_route_table.private-rt.id
}
resource "aws_security_group" "my-websg" {
  name   = "my-websg"
  vpc_id = aws_vpc.custom-vpc.id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
}
resource "aws_security_group" "my-appsg" {
  name   = "my-appsg"
  vpc_id = aws_vpc.custom-vpc.id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["10.0.1.0/24"]
    from_port   = 9000
    protocol    = "tcp"
    to_port     = 9000
  }
}
resource "aws_security_group" "my-dbsg" {
  name   = "my-dbsg"
  vpc_id = aws_vpc.custom-vpc.id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["10.0.2.0/24"]
    from_port   = 3306
    protocol    = "tcp"
    to_port     = 3306
  }
}
resource "aws_key_pair" "tf-key-pair" {
  key_name   = "3teir-key"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "3tier-key"
}
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.ins_type
  vpc_security_group_ids = [aws_security_group.my-websg.id]
  subnet_id = aws_subnet.websubnet.id
  associate_public_ip_address = true
  tags = {
    Name = "webserver"
  }
  key_name = "3teir-key"
provisioner "remote-exec" {
  inline = [
    "sudo yum update -y",
    "sudo yum install nginx -y",
    "sudo service nginx start",
    "sudo sh -c 'echo <h1>Hello from Three tier web app</h1> > /usr/share/nginx/html/index.html'"
]
}
connection {
  type = "ssh"
  user = "ec2-user"
  host =self.public_ip
  private_key =tls_private_key.rsa.private_key_pem
}
}
resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.ins_type
  vpc_security_group_ids = [aws_security_group.my-appsg.id]
  subnet_id = aws_subnet.appsubnet.id
  associate_public_ip_address = false
  tags = {
    Name = "appserver"
  }
  key_name = "3teir-key"
}
resource "aws_db_instance" "my-rds" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Pass1234"
  vpc_security_group_ids = [aws_security_group.my-dbsg.id]
  db_subnet_group_name = aws_db_subnet_group.my-subnet-grp.name
  skip_final_snapshot  = true
}
resource "aws_db_subnet_group" "my-subnet-grp" {
  name       = "my-sub-grp"
  subnet_ids = [aws_subnet.appsubnet.id, aws_subnet.dbsubnet.id]
 
  tags = {
    Name = "My DB subnet group"
  }
}




