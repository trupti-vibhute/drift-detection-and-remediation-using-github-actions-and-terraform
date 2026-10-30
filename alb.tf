# Request flow: Internet -> ALB (public subnets) -> Listener :80 -> Target Group -> EC2 (private subnets)
# ALB and Target Group names must be unique per account + region, so they include the environment

resource "aws_lb" "app_lb" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
  idle_timeout               = 60

  tags = {
    Name = "${var.environment}-alb"
  }
}

# The ASG registers its instances here; the ALB only sends traffic to targets that pass the health check
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.environment}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.environment}-app-tg"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
