#Company Name
variable "victim_company" {
  type        = string
  description = "For naming purposes"
  default     = "goofdemo"
}

#AWS Region
variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-2"
}

#AWS AZ
variable "primary_az" {
  description = "primary AZ"
  default     = "us-east-2a"
}

#AWS VPC CIDR
variable "aws_vpc_cidr" {
  description = "aws vpc cidr"
  type        = string
  default = "10.0.0.0/16"
}

#AWS Subnet CIDR
variable "aws_subnet_cidr" {
  description = "aws subnet cidr"
  type        = string
  default = "10.0.0.0/24"
}

#Server Private IP
variable "goof_private" {
  description = "goof_private_ip"
  type        = string
  default     = "10.0.0.10"
}

#Source IP address
variable "source_ip" {
  description = "source ip"
  type        = string
  default = "0.0.0.0/0"
}

#AMI - You must adjust this based on the region you're in
variable "ubuntu_ami" {
  default = "ami-06b263d6ceff0b3dd"
}


#Key Pair Name
variable "key_name" {
  description = "Desired name of AWS key pair"
}

