# Blueprint for every EC2 instance the Auto Scaling Group launches
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Installs Docker and starts the app container on first boot
  user_data = filebase64("${path.module}/scripts/user_data.sh")

  # Require IMDSv2 (token-based instance metadata) - blocks a common credential-theft path
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-app-instance"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.environment}-app-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-instance"
    propagate_at_launch = true
  }

  # Autoscaling changes desired_capacity on its own. Without this, every drift check
  # would see that as drift and auto-remediation would undo the scaling.
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Target Tracking Scaling - keeps average CPU across the group around 70%
# AWS creates and manages the scale-out / scale-in CloudWatch alarms for this policy
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.environment}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
