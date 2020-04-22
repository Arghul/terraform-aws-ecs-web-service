variable "enable" {
  description = "Whether to enable or disable module"
  type        = bool
  default     = true
}

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

variable "short_name" {
  description = "Whether to use a short name for service or long (namespace-environment-(stage)-(attributes)-name)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC Id"
  type        = string
}

variable "security_group_ids" {
  description = "List of security groups to assign to ALB, ie: ecs cluster sg"
  type        = list
  default     = []
}

variable "public_subnet_ids" {
  description = "Subnet ids to launch ALBs into"
  type        = list
}

variable "access_log_bucket" {
  description = "ALB access log bucket"
  type        = string
}

variable "access_log_prefix" {
  description = "ALB access log prefix. If not set it defaults to `name`"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_healthy_threshold" {
  description = "Health check healthy threshold"
  type        = string
  default     = "3"
}

variable "health_check_interval" {
  description = "Health check interval"
  type        = string
  default     = "30"
}

variable "alb_target_group_port" {
  description = "Port that load balancer uses when forwards the traffic onto instances"
  type        = string
  default     = 80
}

variable "ssl_certificate_arn" {
  description = "SSL certificate arn"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}


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

variable "container_port" {
  description = "Port on which service is running in a container"
  type = number
  default     = 80
}

variable "container_definitions" {
  description = "Container definitions specification in json format"
  type        = string
  default     = ""
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

variable "task_cpu" {
  description = "CPU allocated to run a task"
  default     = 20
  type        = number
}

variable "task_mem" {
  description = "Memory allocated to run a task"
  default     = 128
  type        = number
}

variable "tasks" {
  description = "List of services to run"
  default     = []
  type        = any
}

variable "task_image" {
  description = "Image to use ie: nginx, nginxdemos/hello"
  type        = string
}

variable "allow_cidr_blocks" {
  description = "CIDR blocks to allow access the service"
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "volume" {
  description = "Persistent storage to attach to services (efs|ebs). Default none"
  type = map(string)
  default = {
    type = "none"
  }
}