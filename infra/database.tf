# Defines which subnets RDS is permitted to run in
resource "aws_db_subnet_group" "db" {
  name       = "${var.group_name}-db"
  subnet_ids = data.aws_subnets.default.ids
}

# Managed RDS PostgreSQL Instance
resource "aws_db_instance" "tasks" {
  identifier     = "${var.group_name}-tasks"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = "tasks"
  username = "tasks"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 0
  skip_final_snapshot     = true
}
