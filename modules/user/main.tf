variable "username" {}
variable "pgp_key" {}

resource "aws_iam_user" "u" {
  name          = "${var.username}"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user_login_profile" "u" {
  user    = "${aws_iam_user.u.name}"
  pgp_key = "${var.pgp_key}"
}

output "encrypted_password" {
  value = "${aws_iam_user_login_profile.u.encrypted_password}"
}

output "key_fingerprint" {
  value = "${aws_iam_user_login_profile.u.key_fingerprint }"
}

output "username" {
  value = "${var.username}"
}
