data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ecs_cluster" "service" {
  cluster_name = var.cluster_name
}

data "aws_lb_listener" "service" {
  arn = var.alb_listener_arn
}

data "aws_lb" "service" {
  arn = data.aws_lb_listener.service.load_balancer_arn
}

data "aws_route53_zone" "selected" {
  count   = var.zone_id == null ? 0 : 1
  zone_id = var.zone_id
}

data "aws_secretsmanager_secret" "secrets" {
  count = length(var.secrets)
  arn   = var.secrets[count.index].valueFrom
}

resource "aws_lb_target_group" "service" {
  count                = var.create ? 1 : 0
  name                 = var.name
  port                 = var.service_port
  protocol             = "HTTP"
  vpc_id               = data.aws_lb.service.vpc_id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay
  slow_start           = var.slow_start

  health_check {
    enabled             = true
    interval            = var.health_check_interval
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = var.health_check_http_codes
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = var.stickiness_enabled
    cookie_duration = var.stickiness_duration
  }

  tags = merge(var.tags, var.lb_target_group_tags)
}

resource "aws_lb_listener_rule" "service" {
  count        = var.create ? 1 : 0
  listener_arn = data.aws_lb_listener.service.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[count.index].arn
  }
  condition {
    path_pattern {
      values = var.path_patterns
    }
  }
  condition {
    host_header {
      values = var.host_headers != null ? var.host_headers : var.dns_name != null ? ["${var.dns_name}.${join("", data.aws_route53_zone.selected.*.name)}"] : ["${var.name}.${join("", data.aws_route53_zone.selected.*.name)}"]
    }
  }
  priority = var.priority
  tags     = merge(var.tags, var.lb_listener_rule_tags)
}

resource "aws_cloudwatch_log_group" "service" {
  count             = var.create ? 1 : 0
  name              = var.name
  retention_in_days = 3
  tags              = merge(var.tags, var.cloudwatch_log_group_tags)
}

resource "aws_security_group" "service" {
  count  = var.create ? 1 : 0
  name   = "${var.name}-task"
  vpc_id = data.aws_lb.service.vpc_id

  ingress {
    description = "Allowed"
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, var.security_group_tags)
}

#------------------------------------------------------------------------------
# Task Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "task" {
  count              = var.create ? 1 : 0
  name               = "${var.name}-task"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]},
      "Action": [ "sts:AssumeRole" ]
  }]
}
EOF
  tags               = merge(var.tags, var.task_iam_role_tags)
}

data "aws_iam_policy_document" "task_role_policy" {

  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = [
      "*"
    ]
  }

   statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "xray:PutTraceSegments",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "ssm:DescribeParameters"
    ]
    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.parameter_paths
    content {
      actions = [
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = [
        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${statement.value}"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.parameter_paths_write
    content {
      actions = [
        "ssm:PutParameter",
        "ssm:DeleteParameter",
        "ssm:GetParameterHistory",
        "ssm:GetParametersByPath",
        "ssm:GetParameters",
        "ssm:GetParameter",
        "ssm:DeleteParameters",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = [
        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${statement.value}"
      ]
    }
  }

  dynamic statement {
    for_each = length(var.secrets) > 0 ? [1] : []
    content {
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = data.aws_secretsmanager_secret.secrets.*.arn
    }
  }

  dynamic "statement" {
    for_each = length(var.secrets) > 0 && can(data.aws_secretsmanager_secret.secrets.*.kms_key_id) ? [1] : []
    content {
      actions   = ["kms:Decrypt"]
      resources = distinct(data.aws_secretsmanager_secret.secrets.*.kms_key_id)
    }
  }

  # Add the APS (Prometheus) RemoteWrite Permission
  statement {
    actions = [
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:PutMetricData",
      "aps:RemoteWrite"
    ]
    resources = [
      "*"
    ]
  }
}


resource "aws_iam_role_policy" "task" {
  count  = var.create ? 1 : 0
  name   = "${var.name}-task"
  role   = aws_iam_role.task[count.index].id
  policy = data.aws_iam_policy_document.task_role_policy.json
}

#------------------------------------------------------------------------------
# ECS Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "ecs" {
  count              = var.create && var.ecs_role_arn == null ? 1 : 0
  name               = "${var.name}-ecs"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]},
      "Action": [ "sts:AssumeRole" ]
  }]
}
EOF
  tags               = merge(var.tags, var.ecs_iam_role_tags)
}

data "aws_iam_policy_document" "ecs_role_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "xray:PutTraceSegments",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets"
    ]
    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.dockerhub_secret_arn == "" ? [] : [1]
    content {
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = [
        var.dockerhub_secret_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.parameter_paths
    content {
      actions = [
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = [
        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${statement.value}"
      ]
    }
  }
}

resource "aws_iam_role_policy" "ecs" {
  count  = var.create && var.ecs_role_arn == null ? 1 : 0
  name   = "${var.name}-ecs"
  role   = aws_iam_role.ecs[count.index].id
  policy = data.aws_iam_policy_document.ecs_role_policy.json
}

#------------------------------------------------------------------------------
# ECS Service
#------------------------------------------------------------------------------
locals {
  otel_ssm_config_content_param_arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.otel_ssm_config_param}"
  credentials = var.dockerhub_secret_arn == "" ? "" : <<EOF
    "repositoryCredentials": {
      "credentialsParameter": "${var.dockerhub_secret_arn}"
    },
EOF
}

resource "aws_ecs_task_definition" "service" {
  count                    = var.create ? 1 : 0
  family                   = var.name
  execution_role_arn       = var.ecs_role_arn != null ? var.ecs_role_arn : aws_iam_role.ecs[count.index].arn
  task_role_arn            = aws_iam_role.task[count.index].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  ephemeral_storage {
    size_in_gib = var.ephemeral_storage
  }
  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${var.image}",
    "cpu": ${var.cpu - 256},
    "memory": ${var.memory},
    "essential": true,
    "mountPoints": [],
    "volumesFrom": [],
    "portMappings": [
      {
        "containerPort": ${var.service_port},
        "hostPort": ${var.service_port},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.service[count.index].name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "${var.name}"
      }
    },
    ${local.credentials}
    "environment": ${jsonencode(var.environment_variables)},
    "secrets": ${jsonencode(var.secrets)}
  }
  %{ if var.enable_otel_collector },
  {
    "name": "${var.otel_container_name}",
    "image": "${var.otel_image}",
    "cpu": ${var.otel_cpu},
    "memory": ${var.otel_memory},
    "essential": false,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.service[count.index].name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "aws-otel-collector"
      }
    },
    "healthCheck": {
      "command": ["/healthcheck"],
      "interval": 10,
      "retries": 5,
      "startPeriod": 30,
      "timeout": 5
    },
    %{ if var.otel_ssm_config_param != null }
    "secrets": [
      {
        "name": "AOT_CONFIG_CONTENT",
        "valueFrom": "${local.otel_ssm_config_content_param_arn}"
      }
    ],
    %{ endif }
    "environment": [
      %{ if var.application_metrics_namespace != null && var.application_metrics_log_group != null }
      {
        "name": "ECS_APPLICATION_METRICS_NAMESPACE",
        "value": "${var.application_metrics_namespace}"
      },
      {
        "name": "ECS_APPLICATION_METRICS_LOG_GROUP",
        "value": "${var.application_metrics_log_group}"
      },
      %{ endif }
     %{ for idx, env_var in var.otel_environment_variables }
      {
        "name": "${env_var.name}",
        "value": "${env_var.value}"
      }${idx < length(var.otel_environment_variables) - 1 ? "," : ""}
      %{ endfor }
        ]
      }
    %{ endif }
    ]
EOF
  tags = merge(var.tags, var.ecs_task_definition_tags)
}

resource "aws_ecs_service" "service" {
  count                              = var.create ? 1 : 0
  name                               = var.name
  cluster                            = data.aws_ecs_cluster.service.id
  task_definition                    = aws_ecs_task_definition.service[count.index].arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  enable_execute_command             = var.enable_execute_command

  network_configuration {
    security_groups  = [aws_security_group.service[count.index].id]
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service[count.index].arn
    container_name   = var.name
    container_port   = var.service_port
  }

  depends_on = [
    aws_ecs_task_definition.service,
    aws_lb_target_group.service,
    aws_security_group.service,
    aws_cloudwatch_log_group.service
  ]

  tags = merge(var.tags, var.ecs_service_tags)
}

#------------------------------------------------------------------------------
# ECS Scaling Configuration
#------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "target" {
  count              = var.create ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${data.aws_ecs_cluster.service.cluster_name}/${aws_ecs_service.service[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.desired_count
  max_capacity       = var.max_capacity
  depends_on         = [aws_ecs_service.service]
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  count              = var.create ? 1 : 0
  name               = "${var.name}-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.target[count.index].resource_id
  service_namespace  = aws_appautoscaling_target.target[count.index].service_namespace
  scalable_dimension = aws_appautoscaling_target.target[count.index].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.autoscaling_cpu_up_cooldown
    metric_aggregation_type = var.autoscaling_cpu_up_metric_aggregation_type

    step_adjustment {
      metric_interval_lower_bound = var.autoscaling_cpu_up_metric_interval_lower_bound
      scaling_adjustment          = var.autoscaling_cpu_up_scaling_adjustment
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  count              = var.create ? 1 : 0
  name               = "${var.name}-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.target[count.index].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.autoscaling_cpu_down_cooldown
    metric_aggregation_type = var.autoscaling_cpu_down_metric_aggregation_type

    step_adjustment {
      metric_interval_upper_bound = var.autoscaling_cpu_down_metric_interval_upper_bound
      scaling_adjustment          = var.autoscaling_cpu_down_scaling_adjustment
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  count               = var.create ? 1 : 0
  alarm_name          = "${var.name}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_cpu_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_cpu_high_period
  statistic           = var.alarm_cpu_high_statistic
  threshold           = var.alarm_cpu_high_threshold

  dimensions = {
    ClusterName = data.aws_ecs_cluster.service.cluster_name
    ServiceName = aws_ecs_service.service[count.index].name
  }

  alarm_actions = [aws_appautoscaling_policy.up[count.index].arn]
  tags          = merge(var.tags, var.cloudwatch_metric_alarm_tags)
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  count               = var.create ? 1 : 0
  alarm_name          = "${var.name}_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_cpu_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_cpu_low_period
  statistic           = var.alarm_cpu_low_statistic
  threshold           = var.alarm_cpu_low_threshold

  dimensions = {
    ClusterName = data.aws_ecs_cluster.service.cluster_name
    ServiceName = aws_ecs_service.service[count.index].name
  }

  alarm_actions = [aws_appautoscaling_policy.down[count.index].arn]
  tags          = merge(var.tags, var.cloudwatch_metric_alarm_tags)
}

# Optionally create a DNS record in the provided zone
resource "aws_route53_record" "alb" {
  count   = var.create && var.zone_id != null ? 1 : 0
  name    = var.dns_name == null ? var.name : var.dns_name
  type    = "A"
  zone_id = var.zone_id
  alias {
    name                   = data.aws_lb.service.dns_name
    zone_id                = data.aws_lb.service.zone_id
    evaluate_target_health = true
  }
}
