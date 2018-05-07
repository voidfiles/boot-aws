resource "aws_iam_group" "admins" {
  provider = "aws.users_root"

  name = "Admins"
}

resource "aws_iam_policy" "admin_to_admin" {
  provider    = "aws.users_root"
  name        = "AdminToAdmin"
  description = "A test policy"
  policy      = "${data.aws_iam_policy_document.admin_to_admin.json}"
}

resource "aws_iam_policy_attachment" "attach_admin_to_admin" {
  provider   = "aws.users_root"
  name       = "AdminToAdmin"
  groups     = ["${aws_iam_group.admins.name}"]
  policy_arn = "${aws_iam_policy.admin_to_admin.arn}"
}

data "aws_iam_policy_document" "admin_to_admin" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "${module.development_ou.admin_role_arn}",
      "${module.staging_ou.admin_role_arn}",
      "${module.production_ou.admin_role_arn}",
    ]
  }

  statement {
    sid = "AllowUsersAllActionsForCredentials"

    actions = [
      "iam:ListAttachedUserPolicies",
      "iam:GenerateServiceLastAccessedDetails",
      "iam:*LoginProfile",
      "iam:*AccessKey*",
      "iam:*SigningCertificate*",
      "iam:ListAccessKeys",
      "iam:ChangePassword",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:GetAccessKeyLastUsed",
    ]

    resources = [
      "arn:aws:iam::${var.users_account_id}:user/$${aws:username}",
    ]
  }

  statement {
    sid = "AllowUsersToSeeStatsOnIAMConsoleDashboard"

    actions = [
      "iam:GetAccount*",
      "iam:ListAccount*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowUsersToListUsersInConsole"

    actions = [
      "iam:ListUsers",
    ]

    resources = [
      "arn:aws:iam::${var.users_account_id}:user/*",
    ]
  }

  statement {
    sid = "AllowUsersToListOwnGroupsInConsole"

    actions = [
      "iam:ListGroupsForUser",
    ]

    resources = [
      "arn:aws:iam::${var.users_account_id}:user/$${aws:username}",
    ]
  }

  statement {
    sid = "AllowUsersToCreateTheirOwnVirtualMFADevice"

    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:DeleteVirtualMFADevice",
    ]

    resources = [
      "arn:aws:iam::${var.users_account_id}:mfa/$${aws:username}",
      "arn:aws:iam::${var.users_account_id}:user/$${aws:username}",
    ]
  }

  statement {
    sid = "AllowUsersToListVirtualMFADevices"

    actions = [
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
    ]

    resources = [
      "arn:aws:iam::${var.users_account_id}:*",
    ]
  }
}

module "user_alex" {
  source = "../modules/user"

  providers {
    aws = "aws.users_root"
  }

  username = "voidfiles@gmail.com"
  pgp_key  = "keybase:voidfiles"
}

output "user_alex_encrypted_password" {
  value = "${module.user_alex.encrypted_password}"
}

output "user_alex_key_fingerprint" {
  value = "${module.user_alex.key_fingerprint}"
}

resource "aws_iam_group_membership" "admins" {
  provider = "aws.users_root"
  name     = "admin-membership"

  users = [
    "${module.user_alex.username}",
  ]

  group = "Admins"
}
