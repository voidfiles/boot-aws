module "development_ou" {
  source = "../modules/ou"

  providers {
    aws = "aws.development_root"
  }

  users_account_id = "${var.users_account_id}"
  root_id          = "${var.root_id}"
  environment      = "development"
}

module "staging_ou" {
  source = "../modules/ou"

  providers {
    aws = "aws.staging_root"
  }

  users_account_id = "${var.users_account_id}"
  root_id          = "${var.root_id}"
  environment      = "staging"
}

module "production_ou" {
  source = "../modules/ou"

  providers {
    aws = "aws.production_root"
  }

  users_account_id = "${var.users_account_id}"
  root_id          = "${var.root_id}"
  environment      = "production"
}
