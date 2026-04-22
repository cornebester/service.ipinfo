data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_region" "current" {}

output "role_arn" {
  # This returns the IAM Role ARN (issuer_arn) even if using an assumed role
  value = data.aws_iam_session_context.current.issuer_arn
}
