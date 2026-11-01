terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "group1b-tfstate-598886663596"
    key            = "load-generator/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "group1b-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
