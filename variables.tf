variable "enable" {
  description = "Whether to enable or disable module"
  type        = bool
  default     = true
}

# Label
variable "name" {
  description = "Service name"
}

variable "namespace" {
  description = "Service namespace (eg: api, web, ops)"
}

variable "stage" {
  description = "Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release'"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT'"
  type        = string
}

variable "attributes" {
  description = "Additional attributes"
  type        = list(string)
  default     = []
}

variable "delimiter" {
  description = "Label delimiter"
  type        = string
  default     = "-"
}

variable "tags" {
  description = "Service tags"
  type        = map(string)
  default     = {}
}

# Cluster && Network
variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC Id"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Subnet ids to launch ALBs into"
  type        = list
  default     = []
}

variable "security_group_ids" {
  description = "List of security groups to assign to ALB, ie: ecs cluster sg"
  type        = list
  default     = []
}

variable "allow_cidr_blocks" {
  description = "CIDR blocks to allow access the service"
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "dns_zone_name" {
  description = "DNS zone name to use"
  type        = string
  default     = ""
}

variable "dns_name" {
  description = "DNS name to use. Default to use service name"
  type        = string
  default     = ""
}

variable "dns_record_ttl" {
  description = "DNS record ttl. Default 10 min"
  type        = string
  default     = "10"
}

variable "use_ssl" {
  description = "To enable SSL"
  type        = bool
  default     = true
}

# ALB
variable "access_log_bucket" {
  description = "ALB access log bucket"
  type        = string
  default     = ""
}

variable "access_log_prefix" {
  description = "ALB access log prefix. If not set it defaults to `name`"
  type        = string
  default     = ""
}

variable "alb_health_check" {
  type = object({
    healthy_threshold   = number
    interval            = number
    protocol            = string
    matcher             = number
    timeout             = number
    unhealthy_threshold = number
    path                = string
  })
  default = {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
  }
}

variable "alb_target_group_port" {
  description = "Port that load balancer uses when forwards the traffic onto instances"
  type        = string
  default     = 80
}

# Deployment && Scaling
variable "deployment_min_healthy_percent" {
  description = "Minimum service healthy percent before deployment"
  default     = "100"
  type        = string
}

variable "deployment_max_percent" {
  description = "Maximum service percent during deployment"
  default     = "200"
  type        = string
}

variable "desired_count" {
  description = "Desired number of running tasks"
  default     = "1"
  type        = string
}

variable "min_count" {
  description = "Minimum number of running tasks"
  default     = "1"
  type        = string
}

variable "max_count" {
  description = "Maximum number of running tasks"
  default     = "2"
  type        = string
}

variable "scale_up_cooldown_seconds" {
  description = "Cooldown after scaling up"
  default     = "300"
  type        = string
}

variable "scale_up_threshold" {
  description = "CPU usage treshold above which we consider scaling up ie: 60%"
  type        = string
  default     = "60"
}

variable "scale_down_cooldown_seconds" {
  description = "Cooldown after scaling down"
  default     = "300"
  type        = string
}

variable "scale_down_threshold" {
  description = "CPU usage below which we consider scaling down ie: 15%"
  type        = string
  default     = "15"
}

# Container Definition
variable "container_image" {
  type        = string
  description = "The default container image to use in container definition"
  default     = "cloudposse/default-backend"
}

variable "container_cpu" {
  type        = number
  description = "The vCPU setting to control cpu limits of container. (If FARGATE launch type is used below, this must be a supported vCPU size from the table here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)"
  default     = 256
}

variable "container_memory" {
  type        = number
  description = "The amount of RAM to allow container to use in MB. (If FARGATE launch type is used below, this must be a supported Memory size from the table here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)"
  default     = 512
}

variable "container_ulimits" {
  type = list(object({
    name      = string
    softLimit = number
    hardLimit = number
  }))

  description = "The ulimits to configure for the container. This is a list of maps. Each map should contain \"name\", \"softLimit\" and \"hardLimit\""

  default = []
}

variable "container_memory_reservation" {
  type        = number
  description = "The amount of RAM (Soft Limit) to allow container to use in MB. This value must be less than `container_memory` if set"
  default     = 128
}

variable "container_volumes" {
  type = list(object({
    host_path = string
    name      = string
    docker_volume_configuration = list(object({
      autoprovision = bool
      driver        = string
      driver_opts   = map(string)
      labels        = map(string)
      scope         = string
    }))
  }))
  description = "Task volume definitions as list of configuration objects"
  default     = []
}

variable "container_mount_points" {
  type = list(object({
    containerPath = string
    sourceVolume  = string
  }))

  description = "Container mount points. This is a list of maps, where each map should contain a `containerPath` and `sourceVolume`"
  default     = null
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container. This is a list of maps"
  default     = null
}

variable "container_entrypoint" {
  type        = list(string)
  description = "The entry point that is passed to the container"
  default     = null
}

variable "container_command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = null
}

variable "container_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets to pass to the container. This is a list of maps"
  default     = null
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html
variable "container_healthcheck" {
  type = object({
    command     = list(string)
    retries     = number
    timeout     = number
    interval    = number
    startPeriod = number
  })
  description = "A map containing command (string), timeout, interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy), and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  default     = null
}

variable "container_port" {
  type        = number
  description = "The port number on the container bound to assigned host_port"
  default     = 80
}

variable "container_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"

  default = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
}

variable "init_containers" {
  type = list(object({
    container_definition = any
    condition            = string
  }))
  description = "A list of additional init containers to start. The map contains the container_definition (JSON) and the main container's dependency condition (string) on the init container. The latter can be one of START, COMPLETE, SUCCESS or HEALTHY."
  default     = []
}

variable "task_execution_role_policy_inline" {
  type        = string
  description = "Task execution role policy"
  default     = ""
}

variable "task_execution_role_policy_managed" {
  type        = list(string)
  description = "Task execution role managed policies"
  default = [
    "AmazonSSMFullAccess"
  ]
}

# Cloudwatch Logging
variable "aws_logs_region" {
  type        = string
  description = "The region for the AWS Cloudwatch Logs group"
  default     = "eu-west-1"
}

variable "log_driver" {
  type        = string
  description = "The log driver to use for the container. If using Fargate launch type, only supported value is awslogs"
  default     = "awslogs"
}

variable "log_retention_in_days" {
  description = "Log retention"
  type        = string
  default     = 3
}
