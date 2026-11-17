output "role_arn" {
  description = "The IAM Role ARN to paste into AWS Guardian mobile app"
  value       = aws_iam_role.guardian_role.arn
}

output "role_name" {
  description = "The IAM Role name"
  value       = aws_iam_role.guardian_role.name
}
