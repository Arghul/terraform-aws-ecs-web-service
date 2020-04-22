terraform {
  required_version = "~> 0.12.1"
}

provider "aws" {
  region = var.region
}

module "ecs_service" {
  source = "../"

  name                = "ecs-web"
  namespace           = "arghul"
  environment         = "dev"
  vpc_id              = "vpc-0dc7637eb79ce0c58"
  public_subnet_ids   = ["subnet-078ded0cc969ddabe", "subnet-08f2ece121a14df3e"]
  access_log_bucket   = ""
//  access_log_prefix   = "ALB"
//  health_check_path   = "/"
//  ssl_certificate_arn = ""
  tasks = [
    {
      name       = "api1"
      task_image = "nginxdemos/hello"
      allow_cidr_blocks = [
        "1.1.1.1/32"
      ]
    },
    {
      name       = "web1"
      task_image = "nginxdemos/hello"
      cpu        = 10
    }
  ]
  task_image = "nginxdemos/hello"

  security_group_ids = ["sg-0ab628bd0f2831584"]

  cluster_name                   = "arghul-dev-ecs"
  scale_up_cooldown_seconds      = "30"
  scale_down_cooldown_seconds    = "30"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
}
