data "aws_iam_policy_document" "vault_policy_doc" {
  statement {
    sid = "1"

    actions = [
      "r53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:${var.region}:route53:::hostedzone/${var.hosted_zone_id}",
    ]
  }
}

resource "aws_iam_policy" "vault_policy" {
  name   = "VaultInstancePolicy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.vault_policy_doc.json}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_efs_file_system" "vault" {
  creation_token = "vault"
}

resource "aws_efs_mount_target" "vault" {
  count          = "${length(var.subnet_ids)}"
  file_system_id = "${aws_efs_file_system.vault.id}"
  subnet_id      = "${var.subnet_ids[this.count]}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/userdata.sh")}"

  vars {
    vault_version = "${var.version}"
  }
}

resource "aws_launch_configuration" "vault" {
  name_prefix                 = "vault"
  image_id                    = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.nano"
  iam_instance_profile        = "${aws_iam_policy.vault_policy.name}"
  associate_public_ip_address = true
  user_data                   = "${data.template_file.userdata.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "vault" {
  name_prefix               = "vault"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  launch_configuration      = "${aws_launch_configuration.foobar.name}"
  vpc_zone_identifier       = "${var.subnet_ids}"
}
