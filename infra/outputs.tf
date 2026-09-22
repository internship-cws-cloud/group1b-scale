output "app_url" {
  description = "Application Public URL"
  value       = "http://${aws_lb.web.dns_name}"
}

output "db_endpoint" {
  description = "Database Host Address"
  value       = aws_db_instance.tasks.address
}
