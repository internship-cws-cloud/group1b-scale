output "state_bucket_name" {
  description = "S3 bucket used for Terraform state"
  value       = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.lock.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.me.account_id
}

output "plan_role_arn" {
  description = "GitHub Actions pull-request plan role"
  value       = aws_iam_role.plan.arn
}

output "deploy_role_arn" {
  description = "GitHub Actions main-branch deployment role"
  value       = aws_iam_role.deploy.arn
}
