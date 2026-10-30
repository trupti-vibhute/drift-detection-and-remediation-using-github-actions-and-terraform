output "environment" {
  description = "The environment these resources belong to"
  value       = var.environment
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "load_balancer_url" {
  description = "Open this in a browser to reach the app"
  value       = "http://${aws_lb.app_lb.dns_name}"
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_lb.arn
}

output "alb_security_group_id" {
  description = "ALB security group - target for the manual drift test (add an SSH rule here)"
  value       = aws_security_group.alb_sg.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "s3_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "nat_gateway_ips" {
  description = "Elastic IPs of the NAT Gateways (1 in dev, 1 per AZ in prod)"
  value       = aws_eip.nat[*].public_ip
}
