terraform {
  required_version = "~> 1.16"

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
