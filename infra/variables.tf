variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "group_name" {
  description = "Short group prefix used for AWS resource names (e.g. group1a)"
  type        = string
}

variable "image_tag" {
  description = "ECR Docker image tag to deploy"
  type        = string
  default     = "v1"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
