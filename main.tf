locals {
  name              = var.short_name ? module.label.name : module.label.id
  access_log_prefix = var.access_log_prefix == "" ? local.name : var.access_log_prefix
  vpc_id            = data.aws_vpc.main.id
  public_subnet_ids = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : data.aws_subnet_ids.public_subnets.ids
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
  name   = "${module.label.id}-service-role"

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
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AttachVolume",
        "ec2:CreateVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:DeleteVolume",
        "ec2:DeleteSnapshot",
        "ec2:CopySnapshot",
        "ec2:DescribeSnapshotAttribute",
        "ec2:DetachVolume",
        "ec2:ModifySnapshotAttribute",
        "ec2:ModifyVolumeAttribute"
      ],
      "Resource": [ "*" ]
    }]
}
  EOF

}

module "cert" {
  source = "git::https://github.com/arghul/terraform-aws-acm.git?ref=tags/0.1.1"

  enable      = var.use_ssl && var.dns_zone_name != "" ? true : false
  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  attributes  = var.attributes
  name        = "${local.name}.${var.dns_zone_name}"
}

#
# Network
#
data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = [
      var.vpc_name
    ]
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.main.id

  filter {
    name = "tag:Namespace"
    values = [
      var.namespace
    ]
  }

  filter {
    name = "tag:Environment"
    values = [
      var.environment
    ]
  }

  filter {
    name = "tag:Type"
    values = [
      "public"
    ]
  }
}

data "aws_security_groups" "ecs" {

  filter {
    name = "tag:Namespace"
    values = [
      var.namespace
    ]
  }

  filter {
    name = "tag:Environment"
    values = [
      var.environment
    ]
  }

  filter {
    name = "tag:Name"
    values = [
      "${var.cluster_name}-sg"
    ]
  }

}


#
# Security group resources
#
resource "aws_security_group" "main" {
  count = var.enable ? 1 : 0

  name   = "${module.label.id}-sg"
  vpc_id = local.vpc_id
  tags   = module.label.tags
}

resource "aws_security_group_rule" "http" {
  count = var.enable ? 1 : 0

  description       = "Managed by terraform"
  type              = "ingress"
  security_group_id = aws_security_group.main[count.index].id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.allow_cidr_blocks
}

resource "aws_security_group_rule" "https" {
  count = var.enable && var.use_ssl ? 1 : 0

  description       = "Managed by terraform"
  type              = "ingress"
  security_group_id = aws_security_group.main[count.index].id
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

  name            = "${module.label.id}-alb"
  security_groups = concat(var.security_group_ids, data.aws_security_groups.ecs.ids, list(aws_security_group.main[count.index].id))
  subnets         = local.public_subnet_ids


  access_logs {
    enabled = var.access_log_bucket != "" ? true : false
    bucket  = var.access_log_bucket
    prefix  = "${local.access_log_prefix}-${module.label.id}"
  }

  tags = module.label.tags
}

resource "aws_alb_target_group" "main" {
  count = var.enable ? 1 : 0

  name = "${module.label.id}-alb-tg"

  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  port     = var.alb_target_group_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  tags = module.label.tags

  depends_on = [
    aws_alb.main
  ]

}

resource "aws_alb_listener" "http" {
  count = var.enable ? 1 : 0

  load_balancer_arn = aws_alb.main[count.index].id
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.use_ssl ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
  dynamic "default_action" {
    for_each = ! var.use_ssl ? [1] : []
    content {
      target_group_arn = aws_alb_target_group.main[count.index].id
      type             = "forward"
    }
  }
}

resource "aws_alb_listener" "https" {
  count = var.enable && var.use_ssl ? 1 : 0

  load_balancer_arn = aws_alb.main[count.index].id
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = module.cert.arn

  default_action {
    target_group_arn = aws_alb_target_group.main[count.index].id
    type             = "forward"
  }

}

#
# DNS setup
#
data "aws_route53_zone" "main" {
  count = var.enable && var.dns_zone_name != "" ? 1 : 0

  name = var.dns_zone_name
}

resource "aws_route53_record" "main" {
  count = var.enable && var.dns_zone_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.dns_name != "" ? var.dns_name : local.name
  type    = "CNAME"
  ttl     = var.dns_record_ttl
  records = [aws_alb.main[0].dns_name]
}

#
# ECS resources
#

resource "aws_ecs_task_definition" "main" {
  count = var.enable ? 1 : 0

  family = local.name
  container_definitions = templatefile("${path.module}/task-definition.json", {
    name        = local.name
    image       = var.task_image
    cpu         = var.task_cpu
    mem         = var.task_mem
    port        = var.container_port
    region      = var.region
    volume_type = var.volume.type
  })

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_cloudwatch_log_group" "app" {
  name              = local.name
  tags              = module.label.tags
  retention_in_days = var.log_retention_in_days
}

data "aws_ecs_task_definition" "main" {
  count = var.enable ? 1 : 0

  task_definition = aws_ecs_task_definition.main[count.index].family

  depends_on = [
    aws_ecs_task_definition.main
  ]
}

resource "aws_ecs_service" "main" {
  count = var.enable ? 1 : 0

  name                               = local.name
  cluster                            = var.cluster_name
  task_definition                    = "${aws_ecs_task_definition.main[count.index].family}:${max(aws_ecs_task_definition.main[count.index].revision, data.aws_ecs_task_definition.main[count.index].revision)}"
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_min_healthy_percent
  deployment_maximum_percent         = var.deployment_max_percent
  iam_role                           = module.service_role.id
  launch_type                        = "EC2"

  load_balancer {
    target_group_arn = aws_alb_target_group.main[count.index].id
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
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_count
  max_capacity       = var.max_count

  depends_on = [
    aws_ecs_service.main,
  ]
}

resource "aws_appautoscaling_policy" "up" {
  count = var.enable ? 1 : 0

  name               = "${module.label.id}-aap-up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[count.index].name}"
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

  name               = "${module.label.id}-aap-down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main[count.index].name}"
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

  alarm_name          = "${module.label.id}-alarmCPUUtilizationHigh"
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

  alarm_actions = [aws_appautoscaling_policy.up[count.index].arn]
  tags          = module.label.tags
}

resource "aws_cloudwatch_metric_alarm" "app_service_low_cpu" {
  count = var.enable ? 1 : 0

  alarm_name          = "${module.label.id}-alarmCPUUtilizationLow"
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

  alarm_actions = [aws_appautoscaling_policy.down[count.index].arn]
  tags          = module.label.tags
}
