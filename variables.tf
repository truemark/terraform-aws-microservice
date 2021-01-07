#------------------------------------------------------------------------------
# Required Inputs
#------------------------------------------------------------------------------
variable "name" {}

variable "cluster_name" {}

variable "alb_listener_arn" {}

variable "image" {}

variable "dockerhub_secret_arn" {
  default = ""
}

variable "subnet_ids" {
  type = list(string)
}

variable "assign_public_ip" {
  default = false
}

variable "host_headers" {
  type = list(string)
}

variable "parameter_paths" {
  type = list(string)
  default = []
}

#------------------------------------------------------------------------------
# Service Options
#------------------------------------------------------------------------------

variable "task_role_policy_statements" {
  default = ""
}

variable "zone_id" {
  description = "If populated, will create a Route 53 DNS record for this ALB"
  default = null
}

variable "path_patterns" {
  type = list(string)
  default = ["/*"]
}

variable "priority" {
  default = null
}

variable "service_port" {
  default = 8080
}

variable "environment_variables" {
  default = {}
}

variable "cpu" {
  default = 2048
}

variable "memory" {
  default = 4096
}

variable "desired_count" {
  default = 2
}

variable "deployment_maximum_percent" {
  default = 200
}

variable "deployment_minimum_healthy_percent" {
  default = 100
}

variable "max_capacity" {
  default = 10
}

variable "ingress_cidrs" {
  default = ["0.0.0.0/0"]
}

#------------------------------------------------------------------------------
# Scaling Options
#------------------------------------------------------------------------------

variable "autoscaling_cpu_up_metric_aggregation_type" {
  description = "Valid values are Minimum, Maximum, and Average"
  default = "Average"
}

variable "autoscaling_cpu_up_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
  default = 10
}

variable "autoscaling_cpu_up_metric_interval_lower_bound" {
  description = "Difference between the alarm threshold and the CloudWatch metric."
  default = 0
}

variable "autoscaling_cpu_up_scaling_adjustment" {
  description = "The number of members by which to scale, when the adjustment bounds are breached"
  default = 2
}

variable "autoscaling_cpu_down_metric_aggregation_type" {
  description = "Valid values are Minimum, Maximum, and Average"
  default = "Average"
}

variable "autoscaling_cpu_down_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes and before the next scaling activity can start"
  default = 60
}

variable "autoscaling_cpu_down_metric_interval_upper_bound" {
  description = "Difference between the alarm threshold and the CloudWatch metric."
  default = 0
}

variable "autoscaling_cpu_down_scaling_adjustment" {
  description = "The number of members by which to scale, when the adjustment bounds are breached"
  default = -1
}

variable "alarm_cpu_high_period" {
  description = "The period in seconds over which the specified statistic is applied"
  default = "60"
}

variable "alarm_cpu_high_threshold" {
  description = "The value against which the specified statistic is compared."
  default = "60"
}

variable "alarm_cpu_high_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  default = "1"
}

variable "alarm_cpu_high_statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  default = "Average"
}

variable "alarm_cpu_low_period" {
  description = "The period in seconds over which the specified statistic is applied"
  default = "60"
}

variable "alarm_cpu_low_threshold" {
  description = "The value against which the specified statistic is compared."
  default = "10"
}

variable "alarm_cpu_low_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  default = "1"
}

variable "alarm_cpu_low_statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  default = "Average"
}

#------------------------------------------------------------------------------
# ALB Target Group Options
#------------------------------------------------------------------------------
variable "deregistration_delay" {
  description = "The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused."
  default = 30
}

variable "slow_start" {
  description = "The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable."
  default = 30
}

variable "health_check_interval" {
  description = "Interval in seconds health should be checked. ex. 10"
  default = 10
}

variable "health_check_path" {
  description = "URL path the health check should use. ex. /actuator/health"
  default = "/health"
}

variable "health_check_timeout" {
  description = "Time in seconds before a health check times out. ex. 5"
  default = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy. ex. 3"
  default = 3
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering the target unhealthy. ex. 3"
  default = 3
}

variable "health_check_http_codes" {
  description = "The HTTP status codes to accept for a health check. ex. 200-299"
  default = "200-400"
}

variable "stickiness_enabled" {
  default = false
}

variable "stickiness_duration" {
  description = "The time period, in seconds, during which requests from a client should be routed to the same target. Default is 86400 (24 hours)"
  default = 86400
}
