# Specify the provider and access details
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.14.0"
    }
  }
cloud {
    organization = ""
    workspaces {
      name = ""
    }
  }
}
provider "aws" {
  region = var.aws_region
}
