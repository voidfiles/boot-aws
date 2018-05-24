resource "tls_private_key" "root" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "aws_s3_bucket_object" "root_public" {
  key        = "/ca/root.public.pem"
  bucket     = "${aws_s3_bucket.private.id}"
  content    = "${tls_private_key.root.public_key_pem}"
  kms_key_id = "${aws_kms_key.private.arn}"
}

resource "aws_s3_bucket_object" "root_private" {
  key        = "/ca/root.private.pem"
  bucket     = "${aws_s3_bucket.private.id}"
  content    = "${tls_private_key.root.private_key_pem}"
  kms_key_id = "${aws_kms_key.private.arn}"
}
