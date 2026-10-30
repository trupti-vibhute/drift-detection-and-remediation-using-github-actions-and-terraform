# Traffic allowed:  Internet --80--> ALB (alb_sg) --80--> EC2 (app_sg)
#
# Rules are written INLINE (ingress/egress blocks) on purpose: Terraform then owns the
# complete rule set of each group, so any rule added manually in the console shows up
# as drift and is removed on the next apply. Standalone rule resources would only track
# their own rules and silently ignore extra ones.

# Security Group for Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# Security Group for EC2 Instances (App Tier) - only reachable from the ALB
resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-app-sg"
  description = "Security group for application instances - only allow traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound (for package and image downloads via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}
