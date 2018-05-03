output "admin_role_arn" {
  value = "${aws_iam_role.users_admin_role.arn}"
}
