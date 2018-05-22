variable "vpc_id" {
  description = "The id of the VPC where this vault will be hosted."
}

variable "subnet_ids" {
  description = "The subnet_ids where the hosts should come up. They must be public."
  type        = "list"
}

variable "root_domain" {
  description = "The root domain to build on top of."
}

variable "version" {
  description = "The version of vault to install."
  default     = "0.10.1"
}
