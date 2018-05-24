module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${terraform.workspace}"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway       = false
  enable_vpn_gateway       = false
  enable_dhcp_options      = true
  dhcp_options_domain_name = "internal.brntgarlic.com"
  dhcp_options_ntp_servers = ["169.254.169.123"]

  tags = "${var.default_tags}"
}
