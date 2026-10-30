output "state_bucket_name" {
  description = "Use this as 'bucket' in backend-dev.hcl and backend-prod.hcl"
  value       = aws_s3_bucket.tf_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the state bucket"
  value       = aws_s3_bucket.tf_state.arn
}
