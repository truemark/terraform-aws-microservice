# ECS Service Terraform Module

This Terraform module provisions an ECS Fargate service with optional OpenTelemetry (OTEL) integration and related infrastructure, including load balancers, IAM roles, auto-scaling, and monitoring via CloudWatch.

## Features

-   **ECS Task Definition and Service**: Deploy a containerized application with support for multiple containers.
-   **OpenTelemetry Integration**: Optional OTEL container for advanced observability and monitoring.
-   **Load Balancer Integration**: Configures ALB, target groups, and listener rules.
-   **Scaling**: Configures auto-scaling policies with CloudWatch alarms.
-   **Secrets Management**: Integrates with AWS Secrets Manager for secure environment variable management.

---

## Usage

### Example Without OpenTelemetry

```hcl
module "service" {
  source                 = "./path-to-module"
  name                   = "my-service"
  cluster_name           = "my-cluster"
  alb_listener_arn       = "arn:aws:elasticloadbalancing:region:account-id:listener/listener-id"
  image                  = "my-docker-image:latest"
  dockerhub_secret_arn   = "arn:aws:secretsmanager:region:account-id:secret:dockerhub-secret-id"
  subnet_ids             = ["subnet-abc123", "subnet-def456"]
  host_headers           = ["my-service.example.com"]
  environment_variables  = [
    {
      name  = "Example_VAR"
      value = "example"
    }
  ]
  parameter_paths                 = ["/app/my-service/*"]
  zone_id                         = "Z12345ABCDEF"
  desired_count                   = 2
  autoscaling_cpu_up_scaling_adjustment = 5
  max_capacity                    = 10
  health_check_interval           = 30
  health_check_timeout            = 5
  health_check_path               = "/health"
  slow_start                      = 60
  cpu                             = 2048
  memory                          = 4096
  enable_otel_collector           = false
}

```

### Example With OpenTelemetry

```hcl
module "service" {
  source                 = "./path-to-module"
  name                   = "my-service-dev"
  cluster_name           = "my-cluster"
  alb_listener_arn       = "arn:aws:elasticloadbalancing:region:account-id:listener/listener-id"
  image                  = "my-docker-image:latest"
  dockerhub_secret_arn   = "arn:aws:secretsmanager:region:account-id:secret:dockerhub-secret-id"
  subnet_ids             = ["subnet-abc123", "subnet-def456"]
  host_headers           = ["my-service.example.com"]
  environment_variables  = [
    {
      name  = "Example_VAR"
      value = "example"
    }
  ]
  parameter_paths                 = ["/app/my-service/*"]
  zone_id                         = "Z12345ABCDEF"
  desired_count                   = 2
  autoscaling_cpu_up_scaling_adjustment = 5
  max_capacity                    = 10
  health_check_interval           = 30
  health_check_timeout            = 5
  health_check_path               = "/health"
  slow_start                      = 60
  cpu                             = 2048
  memory                          = 4096
  enable_otel_collector           = true
  otel_ssm_config_param           = "/app/global/otel" //By default it's /app/global/otel only add if you want to override
  otel_environment_variables = [
    {
      name  = "CLUSTER_NAME"
      value = "ecs-cluster"
    },
    {
      name  = "SERVICE_NAME"
      value = "ecs-service"
    },
    {
      name  = "ENVIRONMENT_NAME"
      value = "dev"
    },
    {
      name  = "REGION"
      value = "us-west-2"
    }
  ]
}
```

---

## Inputs

| Variable Name                        | Type           | Description                                                                                                                                                                      | Default Value                                                |
| ------------------------------------ | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `create`                             | `bool`         | Setting this to false prevents the creation of all resources.                                                                                                                    | `true`                                                       |
| `name`                               | `string`       | (Optional, Forces new resource) Name of the target group. If omitted, Terraform will assign a random, unique name.                                                               | `null`                                                       |
| `enable_execute_command`             | `bool`         | Enable execution through SSM.                                                                                                                                                    | `true`                                                       |
| `enable_otel_collector`              | `bool`         | Enable OpenTelemetry Collector.                                                                                                                                                  | `false`                                                      |
| `otel_image`                         | `string`       | The container image to use for the OTEL (OpenTelemetry) container.                                                                                                               | `public.ecr.aws/aws-observability/aws-otel-collector:latest` |
| `otel_container_name`                | `string`       | The name of the OpenTelemetry Collector container.                                                                                                                               | `otel-collector`                                             |
| `otel_cpu`                           | `number`       | The CPU allocation for the OpenTelemetry container.                                                                                                                              | `256`                                                        |
| `otel_memory`                        | `number`       | The memory allocation for the OpenTelemetry container in MiB.                                                                                                                    | `512`                                                        |
| `otel_environment_variables`         | `list(map)`    | The environment variables to pass to a otel container. This parameter maps to Env in the Create a container section of the Docker Remote API and the --env option to docker run. | `[]`                                                         |
| `application_metrics_namespace`      | `string`       | The namespace for CW application metrics.                                                                                                                                        | `null`                                                       |
| `application_metrics_log_group`      | `string`       | The log group for CW application metrics.                                                                                                                                        | `null`                                                       |
| `otel_ssm_config_param`              | `string`       | Custom OpenTelemetry configuration.                                                                                                                                              | `null`                                                       |
| `cluster_name`                       | `string`       | The name of the ECS Cluster.                                                                                                                                                     | `null`                                                       |
| `ecs_role_arn`                       | `string`       | Optional ARN of the ECS role. One is created if not provided.                                                                                                                    | `null`                                                       |
| `alb_listener_arn`                   | `string`       | (Required, Forces New Resource) ARN of the load balancer.                                                                                                                        | `null`                                                       |
| `image`                              | `string`       | The docker image to use in the ECS Task Definition.                                                                                                                              | `null`                                                       |
| `dockerhub_secret_arn`               | `string`       | The Docker-Hub ARN value to pass to the Secrets-Manager::GetSecretValue call when constructing the ECS Role Policy Document.                                                     | `""`                                                         |
| `subnet_ids`                         | `list(string)` | The subnet IDs to use in the ECS Service Configuration.                                                                                                                          | `[]`                                                         |
| `assign_public_ip`                   | `bool`         | (Optional) Assign a public IP address to the ENI (Fargate launch type only). Valid values are true or false. Default false.                                                      | `false`                                                      |
| `host_headers`                       | `list(string)` | (Optional) List of host header patterns to match. Wildcard characters supported: \* (matches 0 or more characters) and ? (matches exactly 1 character).                          | `null`                                                       |
| `parameter_paths`                    | `list(string)` | The parameters paths on an AWS Account that will be part of a generated policy for read-only access.                                                                             | `[]`                                                         |
| `parameter_paths_write`              | `list(string)` | The parameter paths on an AWS Account that will be part of a generated policy for read-write access.                                                                             | `[]`                                                         |
| `secrets`                            | `list(object)` | List of secrets with `name` and `valueFrom`.                                                                                                                                     | `[]`                                                         |
| `ephemeral_storage`                  | `number`       | Size of ephemeral storage in GiB.                                                                                                                                                | `21`                                                         |
| `dns_name`                           | `string`       | If populated, will be used when creating the Route53 DNS record. Otherwise defaults to name.                                                                                     | `null`                                                       |
| `zone_id`                            | `string`       | If populated, will create a Route 53 DNS record for this ALB.                                                                                                                    | `null`                                                       |
| `path_patterns`                      | `list(string)` | (Optional) List of path patterns to match against the request URL. Wildcard characters supported: \* (matches 0 or more characters) and ? (matches exactly 1 character).         | `["/*"]`                                                     |
| `priority`                           | `number`       | (Optional) The priority for the rule between 1 and 50000. Leaving it unset will automatically set the rule with the next available priority.                                     | `null`                                                       |
| `service_port`                       | `number`       | (Required) The port value used for both Start port and End port. Default value is 8080.                                                                                          | `8080`                                                       |
| `environment_variables`              | `list(map)`    | The environment variables to pass to a container.                                                                                                                                | `[]`                                                         |
| `cpu`                                | `number`       | (Optional) Number of CPU units used by the task.                                                                                                                                 | `2048`                                                       |
| `memory`                             | `number`       | (Optional) Amount (in MiB) of memory used by the task.                                                                                                                           | `4096`                                                       |
| `desired_count`                      | `number`       | (Optional) Number of instances of the task definition to place and keep running.                                                                                                 | `2`                                                          |
| `deployment_maximum_percent`         | `number`       | (Optional) Upper limit (as a percentage of the service's desiredCount) of the number of running tasks during a deployment.                                                       | `200`                                                        |
| `deployment_minimum_healthy_percent` | `number`       | (Optional) Lower limit (as a percentage of the service's desiredCount) of the number of running tasks during a deployment.                                                       | `100`                                                        |
| `max_capacity`                       | `number`       | (Required) The max capacity of the scalable target.                                                                                                                              | `10`                                                         |
| `ingress_cidrs`                      | `list(string)` | (Optional) List of CIDR blocks.                                                                                                                                                  | `["0.0.0.0/0"]`                                              |
| `tags`                               | `map(string)`  | Tags applied to all resources.                                                                                                                                                   | `{}`                                                         |

---

## Outputs

| Name                  | Description                            |
| --------------------- | -------------------------------------- |
| `service_arn`         | ARN of the ECS service.                |
| `task_definition_arn` | ARN of the ECS task definition.        |
| `load_balancer_dns`   | DNS name of the load balancer.         |
| `route53_record`      | Route 53 DNS record name (if created). |

---

For detailed guidance or issues, refer to the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).
