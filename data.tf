data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = [
      var.vpc_name
    ]
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.main.id

  filter {
    name = "tag:Namespace"
    values = [
      var.namespace
    ]
  }

  filter {
    name = "tag:Environment"
    values = [
      var.environment
    ]
  }

  filter {
    name = "tag:Type"
    values = [
      "public"
    ]
  }
}

data "aws_security_groups" "ecs" {

  filter {
    name = "tag:Namespace"
    values = [
      var.namespace
    ]
  }

  filter {
    name = "tag:Environment"
    values = [
      var.environment
    ]
  }

  filter {
    name = "tag:Name"
    values = [
      "${var.cluster_name}-sg"
    ]
  }
}


