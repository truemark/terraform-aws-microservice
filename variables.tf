#------------------------------------------------------------------------------
# Required Inputs
#------------------------------------------------------------------------------
variable "create" {
  description = "Setting this to false prevents the creation of all resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "(Optional, Forces new resource) Name of the target group. If omitted, Terraform will assign a random, unique name."
}

variable "enable_execute_command" {
  description = "Enable execution through SSM"
  type        = bool
  default     = true
}

#------------------------------------
# OpenTelemetry Collector Configuration
#------------------------------------


variable "enable_otel_collector" {
  description = "Enable OpenTelemetry Collector"
  type        = bool
  default     = false
}

variable "otel_image" {
  description = "The container image to use for the OTEL (OpenTelemetry) container."
  default = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
}

variable "otel_container_name" {
  description = "The name of the OpenTelemetry Collector container."
  type        = string
  default     = "otel-collector"
}

variable "otel_cpu" {
  description = "The CPU allocation for the OpenTelemetry container."
  type        = number
  default     = 256
}

variable "otel_memory" {
  description = "The memory allocation for the OpenTelemetry container in MiB."
  type        = number
  default     = 512
}

variable "otel_ssm_parameter_name" {
  description = "The name of the SSM parameter that contains the OpenTelemetry Collector configuration"
  type        = string
  default     = ""
}

variable "otel_environment_variables" {
  description = "The environment variables to pass to a otel container. This parameter maps to Env in the Create a container section of the Docker Remote API and the --env option to docker run."
  default     = []
}

variable "application_metrics_namespace" {
  description = "The namespace for CW application metrics."
  type        = string
  default     = null
}

variable "application_metrics_log_group" {
  description = "The log group for CW application metrics."
  type        = string
  default     = null
}
variable "otel_ssm_config_param" {
  description = "Custom OpenTelemetry configuration"
  default     = null
  type        = string
}

#------------------------------------
# End OpenTelemetry Collector Configuration
#------------------------------------
variable "cluster_name" {
  description = "The name of the ECS Cluster"
}

variable "ecs_role_arn" {
  description = "Optional ARN of the ECS role. One is created if not provided."
  default     = null
}

variable "alb_listener_arn" {
  description = "(Required, Forces New Resource) ARN of the load balancer."
}

variable "image" {
  description = "The docker image to use in the ECS Task Definition."
}

variable "dockerhub_secret_arn" {
  description = "The Docker-Hub ARN value to pass to the Secrets-Manager::GetSecretValue call when constructing the ECS Role Policy Document."
  default     = ""
}

variable "subnet_ids" {
  description = "The subnet-ids to use in the ECS Service Configuration."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "(Optional) Assign a public IP address to the ENI (Fargate launch type only). Valid values are true or false. Default false."
  default     = false
}

variable "host_headers" {
  description = "(Optional) Contains a single values item which is a list of host header patterns to match. The maximum size of each pattern is 128 characters. Comparison is case insensitive. Wildcard characters supported: * (matches 0 or more characters) and ? (matches exactly 1 character). Only one pattern needs to match for the condition to be satisfied."
  type        = list(string)
  default     = null
}

variable "parameter_paths" {
  description = "The parameters paths on an AWS Account that will be part of a generated policy for read-only access."
  type        = list(string)
  default     = []
}

variable "parameter_paths_write" {
  description = "The parameter paths on an AWS Account that will be part of a generated policy for read-write access."
  type        = list(string)
  default     = []
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "ephemeral_storage" {
  type    = number
  default = 21
}

#------------------------------------------------------------------------------
# Service Options
#------------------------------------------------------------------------------

variable "task_role_policy_statements" {
  description = "Not currently used."
  default     = ""
}

variable "dns_name" {
  description = "If populated, will be used when creating the Route53 DNS record. Otherwise defaults to name."
  default     = null
}

variable "zone_id" {
  description = "If populated, will create a Route 53 DNS record for this ALB"
  default     = null
}

variable "path_patterns" {
  description = "(Optional) Contains a single values item which is a list of path patterns to match against the request URL. Maximum size of each pattern is 128 characters. Comparison is case sensitive. Wildcard characters supported: * (matches 0 or more characters) and ? (matches exactly 1 character). Only one pattern needs to match for the condition to be satisfied. Path pattern is compared only to the path of the URL, not to its query string. To compare against the query string, use a query_string condition."
  type        = list(string)
  default     = ["/*"]
}

variable "priority" {
  description = "(Optional) The priority for the rule between 1 and 50000. Leaving it unset will automatically set the rule with next available priority after currently existing highest rule. A listener can't have multiple rules with the same priority."
  default     = null
}

variable "service_port" {
  description = "(Required) The port value used for both Start port and End port (or ICMP type number if protocol is icmp or icmpv6). Default value is 8080."
  default     = 8080
}

variable "environment_variables" {
  description = "The environment variables to pass to a container. This parameter maps to Env in the Create a container section of the Docker Remote API and the --env option to docker run."
  default     = []
}

variable "cpu" {
  description = "(Optional) Number of cpu units used by the task. If the requires_compatibilities is FARGATE this field is required. Default value is 2048."
  default     = 2048
}

variable "memory" {
  description = "(Optional) Amount (in MiB) of memory used by the task. If the requires_compatibilities is FARGATE this field is required. Default value is 4096."
  default     = 4096
}

variable "desired_count" {
  description = "(Optional) Number of instances of the task definition to place and keep running. Defaults to 0. Do not specify if using the DAEMON scheduling strategy. Default value is 2."
  default     = 2
}

variable "deployment_maximum_percent" {
  description = "(Optional) Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the DAEMON scheduling strategy. Default value is 200."
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "(Optional) Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. Default value is 100."
  default     = 100
}

variable "max_capacity" {
  description = "(Required) The max capacity of the scalable target. Default value is 10."
  default     = 10
}

variable "ingress_cidrs" {
  description = "(Optional) List of CIDR blocks."
  default     = ["0.0.0.0/0"]
}

#------------------------------------------------------------------------------
# Scaling Options
#------------------------------------------------------------------------------

variable "autoscaling_cpu_up_metric_aggregation_type" {
  description = "Valid values are Minimum, Maximum, and Average"
  default     = "Average"
}

variable "autoscaling_cpu_up_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
  default     = 10
}

variable "autoscaling_cpu_up_metric_interval_lower_bound" {
  description = "Difference between the alarm threshold and the CloudWatch metric."
  default     = 0
}

variable "autoscaling_cpu_up_scaling_adjustment" {
  description = "The number of members by which to scale, when the adjustment bounds are breached"
  default     = 2
}

variable "autoscaling_cpu_down_metric_aggregation_type" {
  description = "Valid values are Minimum, Maximum, and Average"
  default     = "Average"
}

variable "autoscaling_cpu_down_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
  default     = 60
}

variable "autoscaling_cpu_down_metric_interval_upper_bound" {
  description = "Difference between the alarm threshold and the CloudWatch metric."
  default     = 0
}

variable "autoscaling_cpu_down_scaling_adjustment" {
  description = "The number of members by which to scale, when the adjustment bounds are breached"
  default     = -1
}

variable "alarm_cpu_high_period" {
  description = "The period in seconds over which the specified statistic is applied"
  default     = "60"
}

variable "alarm_cpu_high_threshold" {
  description = "The value against which the specified statistic is compared."
  default     = "60"
}

variable "alarm_cpu_high_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  default     = "1"
}

variable "alarm_cpu_high_statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  default     = "Average"
}

variable "alarm_cpu_low_period" {
  description = "The period in seconds over which the specified statistic is applied"
  default     = "60"
}

variable "alarm_cpu_low_threshold" {
  description = "The value against which the specified statistic is compared."
  default     = "10"
}

variable "alarm_cpu_low_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  default     = "1"
}

variable "alarm_cpu_low_statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  default     = "Average"
}

#------------------------------------------------------------------------------
# ALB Target Group Options
#------------------------------------------------------------------------------
variable "deregistration_delay" {
  description = "The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused."
  default     = 30
}

variable "slow_start" {
  description = "The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable."
  default     = 30
}

variable "health_check_interval" {
  description = "Interval in seconds health should be checked. ex. 10"
  default     = 10
}

variable "health_check_path" {
  description = "URL path the health check should use. ex. /actuator/health"
  default     = "/health"
}

variable "health_check_timeout" {
  description = "Time in seconds before a health check times out. ex. 5"
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy. ex. 3"
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering the target unhealthy. ex. 3"
  default     = 3
}

variable "health_check_http_codes" {
  description = "The HTTP status codes to accept for a health check. ex. 200-299"
  default     = "200-400"
}

variable "stickiness_enabled" {
  description = "Weather or not the Stickiness configuration block is enabled."
  default     = false
}

variable "stickiness_duration" {
  description = "The time period, in seconds, during which requests from a client should be routed to the same target. Default is 86400 (24 hours)"
  default     = 86400
}

variable "tags" {
  description = "Tags applied to all resources."
  default     = {}
  type        = map(string)
}

variable "lb_target_group_tags" {
  description = "Tags for the load balancer target group resource."
  default     = {}
  type        = map(string)
}

variable "lb_listener_rule_tags" {
  description = "Tags for the load balancer listener rule."
  default     = {}
  type        = map(string)
}

variable "cloudwatch_log_group_tags" {
  description = "Tags for the CloudWatch log group."
  default     = {}
  type        = map(string)
}

variable "security_group_tags" {
  description = "Tags for the security group."
  default     = {}
  type        = map(string)
}

variable "task_iam_role_tags" {
  description = "Tags for the task IAM role."
  default     = {}
  type        = map(string)
}

variable "ecs_iam_role_tags" {
  description = "Tags for the ECS IAM role."
  default     = {}
  type        = map(string)
}

variable "ecs_task_definition_tags" {
  description = "Tags for the ECS task definition."
  default     = {}
  type        = map(string)
}

variable "ecs_service_tags" {
  description = "Tags for the ECS service."
  default     = {}
  type        = map(string)
}

variable "cloudwatch_metric_alarm_tags" {
  description = "Tags for the all cloudwatch metric alarms."
  default     = {}
  type        = map(string)
}





