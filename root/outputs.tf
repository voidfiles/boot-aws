output "root_domain_zone_id" {
  value = "${aws_route53_zone.root.zone_id }"
}

output "root_domain_nameservers" {
  value = "${aws_route53_zone.root.name_servers}"
}
