variable "root_account_id" {
  description = "The root AWS account ID. Should be the only manual signup."
}

variable "root_id" {
  description = "The name of this service."
}

variable "users_account_id" {
  description = "The AWS account ID where users should be managed."
}

variable "environment_account_ids" {
  description = "The AWS account ID of specific isolated functional enviornments."
  type        = "map"
}

variable "internal_domain" {
  description = "The internal domain name for this service."
}

variable "state_bucket_name" {
  default = "state.root"
}

variable "default_tags" {
  type = "map"

  default = {
    "terraform" = "true"
  }
}

provider "aws" {
  alias  = "root"
  region = "us-west-2"
}

provider "aws" {
  alias  = "users_root"
  region = "us-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.users_account_id}:role/OrganizationAccountAccessRole"
    session_name = "terraform"
  }
}

provider "aws" {
  alias  = "development_root"
  region = "us-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.environment_account_ids["development"]}:role/OrganizationAccountAccessRole"
    session_name = "terraform"
  }
}

provider "aws" {
  alias  = "staging_root"
  region = "us-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.environment_account_ids["staging"]}:role/OrganizationAccountAccessRole"
    session_name = "terraform"
  }
}

provider "aws" {
  alias  = "production_root"
  region = "us-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.environment_account_ids["production"]}:role/OrganizationAccountAccessRole"
    session_name = "terraform"
  }
}
