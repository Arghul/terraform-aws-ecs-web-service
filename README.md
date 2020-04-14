# Terraform AWS ECS web service

Terraform module to create AWS ECS web service and load balancer


## Prerequisites
This module has a few dependencies:
* Terraform 0.12

## Examples
```hcl-terraform
module "api_web_service" {
  source = "git::https://github.com/arghul/terraform-aws-ecs-web-service.git?ref=master"

  name                = "api"
  namespace           = "arghul"
  environment         = "prod"
  vpc_id              = "vpc-XXX"
  public_subnet_ids   = ["subnet-XXX", "subnet-YYY"]
  access_log_bucket   = "logs-XXXX"
  access_log_prefix   = "ALB"
  health_check_path   = "/"
  ssl_certificate_arn = ""
  task_image          = "nginxdemos/hello"

  security_group_ids = ["sg-XXX"]

  cluster_name                   = "prod-ecs"
  scale_up_cooldown_seconds      = "30"
  scale_down_cooldown_seconds    = "30"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_log\_bucket | ALB access log bucket | `string` | n/a | yes |
| access\_log\_prefix | ALB access log prefix | `string` | n/a | yes |
| alb\_target\_group\_port | Port that load balancer uses when forwards the traffic onto instances | `string` | `80` | no |
| allow\_cidr\_blocks | CIDR blocks to allow access the service | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| attributes | Additional attributes | `list(string)` | `[]` | no |
| cluster\_name | ECS cluster name | `string` | n/a | yes |
| container\_definitions | n/a | `string` | `"Container definitions specification in json format"` | no |
| container\_port | Port on which service is running in a container | `number` | `80` | no |
| delimiter | Label delimiter | `string` | `"-"` | no |
| deployment\_max\_percent | Maximum service percent during deployment | `string` | `"200"` | no |
| deployment\_min\_healthy\_percent | Minimum service healthy percent before deployment | `string` | `"100"` | no |
| desired\_count | Desired number of running tasks | `string` | `"1"` | no |
| enable | Whether to enable or disable module | `bool` | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | n/a | yes |
| health\_check\_path | n/a | `string` | `"/"` | no |
| max\_count | Maximum number of running tasks | `string` | `"2"` | no |
| min\_count | Minimum number of running tasks | `string` | `"1"` | no |
| name | Service name | `any` | n/a | yes |
| namespace | Service namespace (eg: api, web, ops) | `any` | n/a | yes |
| public\_subnet\_ids | Subnet ids to launch ALBs into | `list` | n/a | yes |
| scale\_down\_cooldown\_seconds | Cooldown after scaling down | `string` | `"300"` | no |
| scale\_down\_threshold | CPU usage below which we consider scaling down ie: 15% | `string` | `"15"` | no |
| scale\_up\_cooldown\_seconds | Cooldown after scaling up | `string` | `"300"` | no |
| scale\_up\_threshold | CPU usage treshold above which we consider scaling up ie: 60% | `string` | `"60"` | no |
| security\_group\_ids | List of security groups to assign to ALB, ie: ecs cluster sg | `list` | `[]` | no |
| short\_name | Whether to use a short name for service or long (namespace-environment-(stage)-(attributes)-name) | `bool` | `false` | no |
| ssl\_certificate\_arn | SSL certificate arn | `string` | `""` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `""` | no |
| tags | Service tags | `map(string)` | `{}` | no |
| task\_cpu | CPU allocated to run a task | `string` | `20` | no |
| task\_image | Image to use ie: nginx, nginxdemos/hello | `string` | n/a | yes |
| task\_mem | Memory allocated to run a task | `string` | `128` | no |
| vpc\_id | VPC Id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| appautoscaling\_policy\_scale\_down\_arn | n/a |
| appautoscaling\_policy\_scale\_up\_arn | n/a |
| id | n/a |
| lb\_dns\_name | n/a |
| lb\_security\_group\_id | n/a |
| lb\_zone\_id | n/a |
| name | n/a |

