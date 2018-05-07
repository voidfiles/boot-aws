terraform {
  backend "s3" {
    key            = "root/root.tfstate"
    region         = "us-west-2"
    dynamodb_table = "root"
    encrypt        = "true"
  }
}
