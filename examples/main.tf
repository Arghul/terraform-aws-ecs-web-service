terraform {
  required_version = "~> 0.12.1"
}

provider "aws" {
  region = var.region
}

module "ecs_service" {
  source = "../"

  name                = "hello-arghul"
  namespace           = "arghul"
  environment         = "dev"
  vpc_name = "arghul-dev-network"
  access_log_bucket   = ""
//  access_log_prefix   = "ALB"
//  health_check_path   = "/"
//  ssl_certificate_arn = ""
  task_image = "nginxdemos/hello"

  dns_zone_name = "dev.arghul.com"
  self_signed_cert = true

  cluster_name                   = "green"
  scale_up_cooldown_seconds      = "30"
  scale_down_cooldown_seconds    = "30"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
}
