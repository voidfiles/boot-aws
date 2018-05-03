resource "aws_iam_role" "users_admin_role" {
  name                 = "UsersAdminRole"
  description          = "This role allows you to administer everything in this account"
  max_session_duration = 10800

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${var.users_account_id}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "users_admin_role_attach" {
  role       = "${aws_iam_role.users_admin_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "${var.root_id}-${var.environment}"
}
