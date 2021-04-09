variable "vpc_id" {}
variable "public_subnets_ids" {}
variable "tags" {}
variable "environment" {}
variable "target_groups_details" {}
variable "domain_name" {}

variable "user_data" {
  default = [
    "default",
    "app1",
    "app2",
    "forum",
    "secret",
  ]
}
variable "ingress_ports" {
  default = ["80", "443", "8888", ]
}
variable "ports" {
  default = {
    ssl_port        = 443
    http_port       = 80
    secret_ssl_port = 8888
  }
}
variable "protocol" {
  default = {
    http  = "HTTP"
    https = "HTTPS"
  }
}
variable "host_headers" {
  default = [
    "",
    "app1.",
    "app2.",
  ]
}
locals {
  any_cidr_block = ["0.0.0.0/0"]
  any_protocol   = "-1"
  http_protocol  = "tcp"
  any_port       = 0
}
