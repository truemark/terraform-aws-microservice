output "task_role_arn" {
  value = join("", aws_iam_role.task.*.arn)
}

output "task_role_name" {
  value = join("", aws_iam_role.task.*.name)
}

output "lb_target_group_id" {
  value = join("", aws_lb_target_group.service.*.id)
}

output "lb_target_group_name" {
  value = join("", aws_lb_target_group.service.*.name)
}

output "lb_target_group_arn" {
  value = join("", aws_lb_target_group.service.*.arn)
}

output "lb_listener_rule_id" {
  value = join("", aws_lb_listener_rule.service.*.id)
}

output "lb_listener_rule_arn" {
  value = join("", aws_lb_listener_rule.service.*.arn)
}

output "cloudwatch_log_group_name" {
  value = join("", aws_cloudwatch_log_group.service.*.name)
}

output "cloudwatch_log_group_id" {
  value = join("", aws_cloudwatch_log_group.service.*.id)
}

output "cloudwatch_log_group_arn" {
  value = join("", aws_cloudwatch_log_group.service.*.arn)
}

output "security_group_name" {
  value = join("", aws_security_group.service.*.name)
}

output "security_group_id" {
  value = join("", aws_security_group.service.*.id)
}

output "security_group_arn" {
  value = join("", aws_security_group.service.*.arn)
}

output "task_iam_role_name" {
  value = join("", aws_iam_role.task.*.name)
}

output "task_iam_role_id" {
  value = join("", aws_iam_role.task.*.id)
}

output "task_iam_role_arn" {
  value = join("", aws_iam_role.task.*.arn)
}

output "task_iam_role_policy_name" {
  value = join("", aws_iam_role_policy.task.*.name)
}

output "task_iam_role_policy_id" {
  value = join("", aws_iam_role_policy.task.*.id)
}

output "ecs_iam_role_name" {
  value = join("", aws_iam_role.ecs.*.name)
}

output "ecs_iam_role_id" {
  value = join("", aws_iam_role.ecs.*.id)
}

output "ecs_iam_role_arn" {
  value = join("", aws_iam_role.ecs.*.arn)
}

output "ecs_iam_role_policy_name" {
  value = join("", aws_iam_role_policy.ecs.*.name)
}

output "ecs_iam_role_policy_id" {
  value = join("", aws_iam_role_policy.ecs.*.id)
}

output "ecs_task_definition_id" {
  value = join("", aws_ecs_task_definition.service.*.id)
}

output "ecs_task_definition_arn" {
  value = join("", aws_ecs_task_definition.service.*.arn)
}

output "ecs_service_name" {
  value = join("", aws_ecs_service.service.*.name)
}

output "ecs_service_id" {
  value = join("", aws_ecs_service.service.*.id)
}

output "appautoscaling_target_id" {
  value = join("", aws_appautoscaling_target.target.*.id)
}

output "up_appautoscaling_policy_name" {
  value = join("", aws_appautoscaling_policy.up.*.name)
}

output "up_appautoscaling_policy_id" {
  value = join("", aws_appautoscaling_policy.up.*.id)
}

output "up_appautoscaling_policy_arn" {
  value = join("", aws_appautoscaling_policy.up.*.arn)
}

output "down_appautoscaling_policy_name" {
  value = join("", aws_appautoscaling_policy.down.*.name)
}

output "down_appautoscaling_policy_id" {
  value = join("", aws_appautoscaling_policy.down.*.id)
}

output "down_appautoscaling_policy_arn" {
  value = join("", aws_appautoscaling_policy.down.*.arn)
}

output "cpu_high_cloudwatch_metric_alarm_id" {
  value = join("", aws_cloudwatch_metric_alarm.service_cpu_high.*.id)
}

output "cpu_high_cloudwatch_metric_alarm_arn" {
  value = join("", aws_cloudwatch_metric_alarm.service_cpu_high.*.arn)
}

output "cpu_low_cloudwatch_metric_alarm_id" {
  value = join("", aws_cloudwatch_metric_alarm.service_cpu_low.*.id)
}

output "cpu_low_cloudwatch_metric_alarm_arn" {
  value = join("", aws_cloudwatch_metric_alarm.service_cpu_low.*.arn)
}

output "route53_record_id" {
  value = join("", aws_route53_record.alb.*.id)
}
