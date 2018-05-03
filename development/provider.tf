provider "aws" {
  region = "us-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::075487493871:role/UsersAdminRole"
    session_name = "terraform"
  }
}
