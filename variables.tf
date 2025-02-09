variable "my_region" {
    type = string
    default = "us-east-1"
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "ami_id" {
    type = string
}

variable "ins_type" {
    type = string
    default = "t2.micro"
}