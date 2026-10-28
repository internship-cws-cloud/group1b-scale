output "app_url" {
  description = "Open this in a browser"
  value       = "http://${aws_lb.web.dns_name}"
}

output "db_endpoint" {
  value = aws_db_instance.tasks.address
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
