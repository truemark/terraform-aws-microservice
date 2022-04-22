output "task_role_arn" {
  value = aws_iam_role.task.arn
}

output "task_role_name" {
  value = aws_iam_role.task.name
}

output "cloudwatch_log_group_id" {
  value = aws_cloudwatch_log_group.service.id
}

output "cloudwatch_log_group_arn" {
  value = aws_cloudwatch_log_group.service.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.service.name
}

output "cloudwatch_log_group_name_prefix" {
  value = aws_cloudwatch_log_group.service.name_prefix
}
