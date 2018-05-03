terraform {
  backend "s3" {
    bucket         = "state.root.brntgarlic.com"
    key            = "root/root.tfstate"
    region         = "us-west-2"
    dynamodb_table = "root"
    encrypt        = "true"
    kms_key_id     = "arn:aws:kms:us-west-2:813574615989:alias/terraform-encryption-key"
  }
}
