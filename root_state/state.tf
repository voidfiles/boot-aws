data "aws_iam_policy_document" "cross_account_terraform_state_bucket" {
  statement {
    sid = "cross-account-terraform-state-bucket-root"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.root_account_id}:root",
      ]
    }

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}/root/*",
    ]
  }

  statement {
    sid = "cross-account-terraform-state-bucket-production"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.root_account_id}:root",
        "arn:aws:iam::${var.environment_account_ids["production"]}:root",
      ]
    }

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}/production/*",
    ]
  }

  statement {
    sid = "cross-account-terraform-state-bucket-staging"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.root_account_id}:root",
        "arn:aws:iam::${var.environment_account_ids["staging"]}:root",
      ]
    }

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}/staging/*",
    ]
  }

  statement {
    sid = "cross-account-terraform-state-bucket-development"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.root_account_id}:root",
        "arn:aws:iam::${var.environment_account_ids["development"]}:root",
      ]
    }

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.id}/development/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "terraform_state_bucket" {
  bucket = "${aws_s3_bucket.terraform_state_bucket.id}"
  policy = "${data.aws_iam_policy_document.cross_account_terraform_state_bucket.json}"
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "${var.state_bucket_name}.${var.internal_domain}"
  acl    = "private"
  tags   = "${var.default_tags}"

  versioning {
    enabled = "true"
  }

  lifecycle {
    prevent_destroy = "true"
  }
}

resource "aws_dynamodb_table" "terraform_statelock_root" {
  name           = "root"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = "${var.default_tags}"
}

data "aws_iam_policy_document" "key_policy" {
  statement {
    sid = "1"

    actions = [
      "kms:*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.root_account_id}:root"]
    }

    resources = [
      "*",
    ]
  }

  statement {
    sid = "2"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.environment_account_ids["development"]}:root",
        "arn:aws:iam::${var.environment_account_ids["staging"]}:root",
        "arn:aws:iam::${var.environment_account_ids["production"]}:root",
      ]
    }

    resources = [
      "*",
    ]
  }

  statement {
    sid = "3"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.environment_account_ids["development"]}:root",
        "arn:aws:iam::${var.environment_account_ids["staging"]}:root",
        "arn:aws:iam::${var.environment_account_ids["production"]}:root",
      ]
    }

    resources = [
      "*",
    ]
  }

  statement {
    sid = "4"

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.environment_account_ids["development"]}:root",
        "arn:aws:iam::${var.environment_account_ids["staging"]}:root",
        "arn:aws:iam::${var.environment_account_ids["production"]}:root",
      ]
    }

    resources = [
      "*",
    ]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true",
      ]
    }
  }
}

resource "aws_kms_key" "terraform_encryption_key" {
  description = "The key for encrypting terraform state in S3"
  policy      = "${data.aws_iam_policy_document.key_policy.json}"
}

resource "aws_kms_alias" "terraform_encryption_key" {
  name          = "alias/terraform-encryption-key"
  target_key_id = "${aws_kms_key.terraform_encryption_key.key_id}"
}

data "template_file" "init" {
  template = "${file("${path.module}/backend.tfvars.tpl")}"

  vars {
    state_bucket_name = "${var.state_bucket_name}"
    internal_domain   = "${var.internal_domain}"
    root_account_id   = "${var.root_account_id}"
  }
}

resource "local_file" "backend_conf" {
  content  = "${data.template_file.init.rendered}"
  filename = "../root/backend.tfvars"
}

resource "local_file" "root_state_backend_conf" {
  content  = "${data.template_file.init.rendered}"
  filename = "./backend.tfvars"
}
