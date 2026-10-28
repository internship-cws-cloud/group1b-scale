output "app_url" {
  description = "URL of the application load balancer"
  value       = "http://${aws_lb.app.dns_name}"
}

output "db_endpoint" {
  value = aws_db_instance.tasks.address
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
