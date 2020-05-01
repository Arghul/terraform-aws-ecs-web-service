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
//  vpc_id              = "vpc-0dc7637eb79ce0c58"
//  public_subnet_ids   = ["subnet-078ded0cc969ddabe", "subnet-08f2ece121a14df3e"]
  access_log_bucket   = ""
//  access_log_prefix   = "ALB"
//  health_check_path   = "/"
//  ssl_certificate_arn = ""
  task_image = "nginxdemos/hello"

//  security_group_ids = ["sg-0b59fa78ac3675db6"]
  dns_zone_name = "dev.arghul.com"
  self_signed_cert = false

  cluster_name                   = "green"
  scale_up_cooldown_seconds      = "30"
  scale_down_cooldown_seconds    = "30"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
}
