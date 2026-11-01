variable "region" {
  description = "AWS region for the remote load generator"
  type        = string
  default     = "eu-west-1"
}

variable "target_url" {
  description = "Public URL of the application ALB"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for k6"
  type        = string
  default     = "t3.small"
}
