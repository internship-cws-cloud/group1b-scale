output "instance_id" {
  description = "EC2 load generator instance ID"
  value       = aws_instance.runner.id
}

output "availability_zone" {
  description = "Availability Zone of the load generator"
  value       = aws_instance.runner.availability_zone
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.runner.instance_type
}
