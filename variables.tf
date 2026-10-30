variable "region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name - passed in by the workflow based on the branch (dev branch -> dev, main branch -> prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "The desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "s3_bucket_prefix" {
  description = "Prefix for the application S3 bucket name (environment and a random suffix are appended)"
  type        = string
  default     = "drift-demo-app-data"
}
