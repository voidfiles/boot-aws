resource "aws_dynamodb_table" "state_lock" {
  name           = "root"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = "${var.default_tags}"
}

terraform {
  backend "s3" {
    bucket         = "state.root.brntgarlic.com"
    key            = "development/development.tfstate"
    region         = "us-west-2"
    dynamodb_table = "root"
    encrypt        = "true"
    role_arn       = "arn:aws:iam::075487493871:role/UsersAdminRole"
    kms_key_id     = "arn:aws:kms:us-west-2:813574615989:alias/terraform-encryption-key"
  }
}
