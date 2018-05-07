output "admin_role_arn" {
  value = "${aws_iam_role.users_admin_role.arn}"
}

output "name_servers" {
  value = "${aws_route53_zone.ou_zone.name_servers}"
}
