# Look up the default VPC in your active AWS account
data "aws_vpc" "default" {
  default = true
}

# Look up all subnets inside that default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
