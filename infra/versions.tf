terraform {
  required_version = "~> 1.9.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  backend "s3" {
    bucket         = "group1b-tfstate-598886663596"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "group1b-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Group     = var.group_name
      Programme = "Thrive-cloud-internship"
      ManagedBy = "terraform"
    }
  }
}
