bucket     = "${state_bucket_name}.${internal_domain}"
kms_key_id = "arn:aws:kms:us-west-2:${root_account_id}:alias/terraform-encryption-key"
