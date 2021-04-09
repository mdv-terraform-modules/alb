data "terraform_remote_state" "network_data" {
  backend = "s3"

  config = {
    bucket = "mdv-terraform-state"
    key    = "module_final/network/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_acm_certificate" "cert" {
  domain = "*.${var.domain_name}"
}
data "aws_acm_certificate" "cert_main" {
  domain = var.domain_name
}
