output "id" {
  value = slice(aws_ecs_service.main.id, 0, 1)
  //  value = aws_ecs_service.main[0].id
}

output "name" {
//  value = aws_ecs_service.main[0].name
  value = slice(aws_ecs_service.main.name, 0, 1)
}

output "lb_zone_id" {
//  value = aws_alb.main[0].zone_id
  value = slice(aws_alb.main.zone_id, 0, 1)
}

output "lb_dns_name" {
//  value = aws_alb.main[0].dns_name
  value = slice(aws_alb.main.dns_name, 0, 1)
}

output "lb_security_group_id" {
//  value = aws_security_group.main[0].id
  value = slice(aws_security_group.main.id, 0, 1)
}

output "appautoscaling_policy_scale_up_arn" {
//  value = aws_appautoscaling_policy.up[0].arn
  value = slice(aws_appautoscaling_policy.up.arn, 0, 1)
}

output "appautoscaling_policy_scale_down_arn" {
//  value = aws_appautoscaling_policy.down[0].arn
  value = slice(aws_appautoscaling_policy.down.arn, 0, 1)
}