locals {
  name                          = var.short_name ? module.label.name : module.label.id
  default_container_definitions = <<EOF
  [
    {
      "name": "${local.name}",
      "image": "${var.task_image}",
      "cpu": ${var.task_cpu},
      "memory": ${var.task_mem},
      "essential": true,
      "portmappings": [
        {
          "containerport": ${var.container_port},
          "protocol": "tcp"
        }
      ]
    }
  ]
  EOF
  container_definitions         = var.container_definitions != "" ? var.container_definitions : local.default_container_definitions
}

module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  name        = var.name
  attributes  = var.attributes
  delimiter   = var.delimiter
  tags        = var.tags
}

module "service_role" {
  source = "git::https://github.com/netf/terraform-aws-iam-role.git?ref=master"
  name   = "${local.name}-service-role"

  allow_service = "ecs.amazonaws.com"

  policy_inline = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": [ "*" ]
    }]
}
  EOF

}


#
# Security group resources
#
resource "aws_security_group" "main" {
  count = var.enable ? 1 : 0

  name   = "${local.name}-sg"
  vpc_id = var.vpc_id
  tags   = module.label.tags
}

resource "aws_security_group_rule" "http" {
  count = var.enable && length(var.ssl_certificate_arn) == 0 ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.main[0].id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.allow_cidr_blocks
}

resource "aws_security_group_rule" "https" {
  count = var.enable && length(var.ssl_certificate_arn) > 0 ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.main[0].id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.allow_cidr_blocks
}

#
# ALB resources
#
resource "aws_alb" "main" {
  count = var.enable ? 1 : 0

  name            = "${local.name}-alb"
  security_groups = concat(var.security_group_ids, list(aws_security_group.main[0].id))
  subnets         = var.public_subnet_ids

  access_logs {
    bucket = var.access_log_bucket
    prefix = var.access_log_prefix
  }

  tags = module.label.tags
}

resource "aws_alb_target_group" "main" {
  count = var.enable ? 1 : 0

  name = "${local.name}-alb-tg"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  port     = var.alb_target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = module.label.tags

  depends_on = [
    aws_alb.main
  ]

}

resource "aws_alb_listener" "http" {
  count = var.enable ? 1 : 0

  load_balancer_arn = aws_alb.main[0].id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main[0].id
    type             = "forward"
  }
}

resource "aws_alb_listener" "https" {
  count = var.enable && length(var.ssl_certificate_arn) > 0 ? 1 : 0

  load_balancer_arn = aws_alb.main[0].id
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = var.ssl_certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.main[0].id
    type             = "forward"
  }
}


#
# ECS resources
#
resource "aws_ecs_task_definition" "main" {
  count = var.enable ? 1 : 0

  family                = local.name
  container_definitions = local.container_definitions

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_ecs_service" "main" {
  count = var.enable ? 1 : 0

  name                               = local.name
  cluster                            = var.cluster_name
  task_definition                    = aws_ecs_task_definition.main[0].id
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_min_healthy_percent
  deployment_maximum_percent         = var.deployment_max_percent
  iam_role                           = module.service_role.id
  launch_type                        = "EC2"

  load_balancer {
    target_group_arn = aws_alb_target_group.main[0].id
    container_name   = local.name
    container_port   = var.container_port
  }

  lifecycle {
    create_before_destroy = true
  }

}

#
# Application AutoScaling resources
#
resource "aws_appautoscaling_target" "main" {
  count = var.enable ? 1 : 0

  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_count
  max_capacity       = var.max_count

  depends_on = [
    aws_ecs_service.main,
  ]
}

resource "aws_appautoscaling_policy" "up" {
  count = var.enable ? 1 : 0

  name               = "${local.name}-aap-up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_up_cooldown_seconds
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [
    aws_appautoscaling_target.main,
  ]
}

resource "aws_appautoscaling_policy" "down" {
  count = var.enable ? 1 : 0

  name               = "${local.name}-aap-down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_down_cooldown_seconds
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [
    aws_appautoscaling_target.main,
  ]
}

resource "aws_cloudwatch_metric_alarm" "app_service_high_cpu" {
  count = var.enable ? 1 : 0

  alarm_name          = "alarmAppCPUUtilizationHigh"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.scale_up_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = local.name
  }

  alarm_actions = [aws_appautoscaling_policy.up[0].arn]
  tags          = module.label.tags
}

resource "aws_cloudwatch_metric_alarm" "app_service_low_cpu" {
  count = var.enable ? 1 : 0

  alarm_name          = "alarmAppCPUUtilizationLow"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.scale_down_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = local.name
  }

  alarm_actions = [aws_appautoscaling_policy.down[0].arn]
  tags          = module.label.tags
}
