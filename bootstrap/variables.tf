variable "region" {
  description = "The AWS region for the state bucket"
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Globally unique name of the S3 bucket that stores Terraform state"
  type        = string
  default     = "tf-state-truptivibhute-day30"
}
