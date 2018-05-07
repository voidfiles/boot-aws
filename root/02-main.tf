resource "aws_route53_zone" "root" {
  name = "${var.internal_domain}"
}

module "development_ou" {
  source = "../modules/ou"

  providers {
    aws = "aws.development_root"
  }

  users_account_id = "${var.users_account_id}"
  root_id          = "${var.root_id}"
  environment      = "development"
  internal_domain  = "${var.internal_domain}"
}

resource "aws_route53_record" "development_root_zone_transfer" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name    = "development.${var.internal_domain}"
  type    = "NS"
  ttl     = "300"
  records = ["${module.development_ou.name_servers}"]
}

module "staging_ou" {
  source = "../modules/ou"

  providers {
    aws = "aws.staging_root"
  }

  users_account_id = "${var.users_account_id}"
  root_id          = "${var.root_id}"
  environment      = "staging"
  internal_domain  = "${var.internal_domain}"
}

resource "aws_route53_record" "staging_root_zone_transfer" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name    = "staging.${var.internal_domain}"
  type    = "NS"
  ttl     = "300"
  records = ["${module.staging_ou.name_servers}"]
}

module "production_ou" {
  source = "../modules/ou"

  providers {
    aws = "aws.production_root"
  }

  users_account_id = "${var.users_account_id}"
  root_id          = "${var.root_id}"
  environment      = "production"
  internal_domain  = "${var.internal_domain}"
}

resource "aws_route53_record" "production_root_zone_transfer" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name    = "production.${var.internal_domain}"
  type    = "NS"
  ttl     = "300"
  records = ["${module.production_ou.name_servers}"]
}
