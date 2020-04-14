output "id" {
  value = aws_ecs_service.main[0].id
}

output "name" {
  value = aws_ecs_service.main[0].name
}

output "lb_zone_id" {
  value = aws_alb.main[0].zone_id
}

output "lb_dns_name" {
  value = aws_alb.main[0].dns_name
}

output "lb_security_group_id" {
  value = aws_security_group.main[0].id
}

output "appautoscaling_policy_scale_up_arn" {
  value = aws_appautoscaling_policy.up[0].arn
}

output "appautoscaling_policy_scale_down_arn" {
  value = aws_appautoscaling_policy.down[0].arn
}