import os

import json

CWD = os.path.dirname(os.path.realpath(__file__))


class OU(object):
    @property
    def POLICY_CONTENT(cls):
        return {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Action": cls.account_allowed_actions,
            "Resource": "*"
          }]
        }


class UserOUDetails(OU):
    NAME = "users"
    POLICY_NAME = "users_ou_policy"
    ROOT_NAME = "users-root"
    EMAIL = "voidfiles+boot-users-root@gmail.com"
    account_allowed_actions = [
        "iam:*",
        "sts:*",
    ]


class DevelopmentOUDetails(OU):
    NAME = "development"
    POLICY_NAME = "development_ou_policy"
    ROOT_NAME = "development-root"
    EMAIL = "voidfiles+boot-development-root@gmail.com"
    account_allowed_actions = [
        "iam:*",
        "sts:*",
        "dynamodb:*",
        "ec2:*",
        "s3:*",
        "kms:*",
    ]


class StagingOUDetails(OU):
    NAME = "staging"
    POLICY_NAME = "staging_ou_policy"
    ROOT_NAME = "staging-root"
    EMAIL = "voidfiles+boot-staging-root@gmail.com"
    account_allowed_actions = [
        "iam:*",
    ]


class ProductionOUDetails(OU):
    NAME = "production"
    POLICY_NAME = "production_ou_policy"
    ROOT_NAME = "production-root"
    EMAIL = "voidfiles+boot-production-root@gmail.com"
    account_allowed_actions = [
        "iam:*",
    ]


class OUS(object):
    USER = UserOUDetails()
    ENVIRONMENTS = {
        "development": DevelopmentOUDetails(),
        "staging": StagingOUDetails(),
        "production": ProductionOUDetails(),
    }

class CONF(object):
    DOMAIN = "brntgarlic.com"
    REGION = "us-west-2"
