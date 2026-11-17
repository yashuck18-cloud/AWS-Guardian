variable "aws_region" {
  type        = string
  description = "AWS region for provider"
  default     = "us-east-1"
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role to create"
  default     = "AWSGuardianRole"
}

variable "guardian_backend_principal_arn" {
  type        = string
  description = "ARN of the AWS Guardian backend IAM identity executing AssumeRole"
  default     = "arn:aws:iam::123456789012:root"
}

variable "external_id" {
  type        = string
  description = "Unique External ID generated from the AWS Guardian mobile application"
}
