terraform {
  required_version = "~> 0.12.1"
}

provider "aws" {
  region = var.region
}

module "api_web_service" {
  source = "../"

  name                = "api"
  namespace           = "arghul"
  environment         = "prod"
  vpc_id              = "vpc-2424bb40"
  public_subnet_ids   = ["subnet-58f79f2e", "subnet-8ee658d6"]
  access_log_bucket   = "logs-bucket-01"
  access_log_prefix   = "ALB"
  health_check_path   = "/"
  ssl_certificate_arn = ""
  task_image          = "nginxdemos/hello"

  security_group_ids = ["sg-008be838c60ccbe9c"]

  cluster_name                   = "arghul-prod-ecs"
  scale_up_cooldown_seconds      = "30"
  scale_down_cooldown_seconds    = "30"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
}
