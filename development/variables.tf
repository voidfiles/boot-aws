variable "domain_name" {
  default = "development.brntgarlic.com"
}

variable "state_bucket_name" {
  default = "state.root.brntgarlic.com"
}

variable "environment" {
  default = "development"
}

variable "default_tags" {
  type = "map"

  default = {
    terraform   = "true"
    environment = "development"
  }
}
