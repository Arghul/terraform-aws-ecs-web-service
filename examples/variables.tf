variable "name" {
  default = "test"
}
variable "stage" {
  default = "dev"
}
variable "namespace" {
  default = "api"
}
variable "delimiter" {
  default = "-"
}
variable "attributes" {
  type    = list(string)
  default = []
}

variable "region" {
  default = "eu-west-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
