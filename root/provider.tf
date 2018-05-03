variable "root_account_id" {
  default = "813574615989"
}

variable "root_id" {
  default = "boot"
}

variable "users_account_id" {
  default = "133430444242"
}

variable "environment_account_ids" {
  type = "map"

  default = {
    development = "075487493871"
    staging     = "200247690167"
    production  = "662903516389"
  }
}

variable "state_bucket_name" {
  default = "state.root.brntgarlic.com"
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
