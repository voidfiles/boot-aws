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

resource "aws_iam_access_key" "lb" {
  user    = "${aws_iam_user.u.name}"
  pgp_key = "${var.pgp_key}"
}

output "encrypted_password" {
  value = "${aws_iam_user_login_profile.u.encrypted_password}"
}

output "key_fingerprint" {
  value = "${aws_iam_user_login_profile.u.key_fingerprint }"
}

output "access_key_id" {
  value = "${aws_iam_access_key.lb.id}"
}

output "encrypted_secret_key" {
  value = "${aws_iam_access_key.lb.encrypted_secret}"
}

output "username" {
  value = "${var.username}"
}
