terraform {
  required_version = "~> 1.16"

  backend "s3" {
    bucket         = "group1b-tfstate-598206843443"
    key            = "group1b/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "group1b-tflock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Group     = var.group_name
      Programme = "cloud-internship"
      ManagedBy = "terraform"
    }
  }
}
