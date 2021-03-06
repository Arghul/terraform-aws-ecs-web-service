terraform {
  required_version = "~> 0.12.1"
}

provider "aws" {
  region = var.region
}

module "ecs_service" {
  source = "../"

  name              = "hello-arghul"
  namespace         = "arghul"
  environment       = "dev"
  vpc_name          = "arghul-dev-network"
  access_log_bucket = ""
  //  access_log_prefix   = "ALB"
  //  health_check_path   = "/"
  //  ssl_certificate_arn = ""
  container_image = "nginxdemos/hello"
  container_cpu   = 128
//  container_port_mappings = [
//    {
//      containerPort = 80
//      hostPort      = 0
//      protocol      = "tcp"
//    }
//  ]
  container_environment = [
    {
      name  = "VAR"
      value = "TEST"
    },
    {
      name  = "FOO"
      value = "TEST"
    }
  ]

  container_port = 80

//  container_secrets = [
//    {
//      name      = "SECRET"
//      valueFrom = "arn:aws:ssm:eu-west-1:076594877490:parameter/arghul/mongo_uri"
//    }
//  ]

  init_containers = [
    {
      container_definition =<<EOF
      {
        "name": "nginx",
        "image": "076594877490.dkr.ecr.eu-west-1.amazonaws.com/nginx-auth-proxy:0.4",
        "memory": 256,
        "cpu": 128,
        "essential": true,
        "portMappings": [
          {
            "containerPort": 80,
            "protocol": "tcp"
          }
        ],
        "links": [ "arghul-dev-hello-arghul" ],
        "dependsOn": [
          {
            "containerName": "arghul-dev-hello-arghul",
            "condition": "START"
          }
        ]
      }
      EOF
      condition = ""
    }
  ]


  dns_zone_name = "dev.arghul.com"
  use_ssl       = false

  cluster_name                   = "arghul-dev-ecs-green"
  scale_up_cooldown_seconds      = "30"
  scale_down_cooldown_seconds    = "30"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
}
