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

provider "tls" {}
