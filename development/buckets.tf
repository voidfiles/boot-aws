// This is where we can store things like secrets and certs
// No file in this bucket should be read outside this environment
resource "aws_s3_bucket" "private" {
  bucket = "private.${var.domain_name}"
  acl    = "private"

  tags {
    Name        = "private"
    Environment = "${var.environment}"
  }
}

resource "aws_kms_key" "private" {
  description = "Key objects in the private bucket"
}
