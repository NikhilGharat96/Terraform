variable "my_region" {
  type    = string
  default = "us-east-1"
}
variable "access_key" {
  type = string
}
variable "secret_key" {
  type = string
}
variable "ami_id" {
  type    = string
  default = "ami-085ad6ae776d8f09c"
}
variable "ins_type" {
  type = map(any)
  default = {
    default = "t2.micro"
    dev     = "t2.nano"
    test    = "t2.small"
    prod    = "t2.medium"
  }
}
