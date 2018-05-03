import boto3
import json

from botocore.exceptions import ClientError

import logging

logger = logging.getLogger(__name__)

def get_client_for_role(client_type, role):
    credentials = role['Credentials']

    return boto3.client(
        client_type,
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
    )


def build_root_org(client):
    response = client.describe_organization()
    organization = response.get("Organization")
    if not organization:
        logger.info("Creating an organization")
        response = client.create_organization(
            FeatureSet='ALL'
        )

        organization = response.get("Organization")

    return organization


def find_root(client):
    response = client.list_roots()
    roots = response.get("Roots", [])
    if not roots:
        raise Exception("Missing a root")

    root = roots[0]

    return root


def get_ous_by_name(client, root):
    response = client.list_organizational_units_for_parent(
        ParentId=root['Id'],
    )

    ous = response.get("OrganizationalUnits", [])

    return {x["Name"]: x for x in ous}


def get_or_create_ou(client, name, root, ous_by_name):
    ou = ous_by_name.get(name)
    if ou:
        return ou

    logger.info("Creating an ou: %s", name)
    response = client.create_organizational_unit(
        ParentId=root["Id"],
        Name=name
    )

    ous_by_name[name] = response.get("OrganizationalUnit")

    return ous_by_name[name]


def get_policies_by_name(client, target=None):
    if target is None:
        response = client.list_policies(
            Filter='SERVICE_CONTROL_POLICY',
        )
    else:
        response = client.list_policies_for_target(
            TargetId=target["Id"],
            Filter='SERVICE_CONTROL_POLICY',
        )

    return {x["Name"]: x for x in response.get("Policies", [])}


def get_or_create_ou_policy(client, policies_by_name, name, content):
    if name not in policies_by_name:
        logger.info("Creating an ou policy: %s", name)
        response = org_client.create_policy(
            Content=json.dumps(content),
            Description='A policy for %s' % (name),
            Name=name,
            Type='SERVICE_CONTROL_POLICY'
        )

        policies_by_name[name] = response.get("Policy")

    return policies_by_name[name]


def enable_policies(client, root):
    try:
        client.enable_policy_type(
            RootId=root['Id'],
            PolicyType='SERVICE_CONTROL_POLICY'
        )
    except ClientError as e:
        if e.response['Error']['Code'] == "PolicyTypeAlreadyEnabledException":
            pass
        else:
            raise


def attach_policy(client, policy, ou):

    try:
        response = client.attach_policy(
            PolicyId=policy['Id'],
            TargetId=ou["Id"],
        )
    except ClientError as e:
        if e.response['Error']['Code'] == "DuplicatePolicyAttachmentException":
            pass
        else:
            raise


def create_root_account_in_ou(client, email, name):
    client.create_account(
        Email=email,
        AccountName=name,
        IamUserAccessToBilling='ALLOW'
    )


def move_account_to_ou(client, account, from_ou, to_ou):
    try:
        client.move_account(
            AccountId=account['Id'],
            SourceParentId=from_ou["Id"],
            DestinationParentId=to_ou["Id"],
        )
    except ClientError as e:
        if e.response['Error']['Code'] == "AccountNotFoundException":
            pass
        else:
            raise


def detach_aws_policy(client, ou):
    target_policies_for_name = get_policies_by_name(
        client, ou)

    if "FullAWSAccess" in target_policies_for_name:
        client.detach_policy(
            PolicyId=target_policies_for_name["FullAWSAccess"]["Id"],
            TargetId=ou["Id"],
        )


def get_accounts_by_name(client):
    response = client.list_accounts()

    accounts = response.get("Accounts", [])
    return {x["Name"]: x for x in accounts}


def update_policy(client, policy, ou):
    client.update_policy(
        PolicyId=policy["Id"],
        Content=json.dumps(ou.POLICY_CONTENT),
    )


def get_or_create_bucket(client, region, bucket_name):
    response = client.list_buckets()
    buckets_by_name = {x["Name"]: x for x in response.get("Buckets", [])}
    if bucket_name not in buckets_by_name:
        client.create_bucket(
            ACL='private',
            CreateBucketConfiguration={
                'LocationConstraint': region,
            },
            Bucket=bucket_name
        )


def get_client_for_account(client, account, assumed_client_type):
    response = client.assume_role(
        RoleArn='arn:aws:iam::%s:role/OrganizationAccountAccessRole' % (
            account["Id"]),
        RoleSessionName='establsh',
    )

    return get_client_for_role(assumed_client_type, response)


def _build_assume_role_policy(identifiers=None):
    identifiers = identifiers if identifiers else []

    return json.dumps({
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Principal": {
             "AWS": identifiers,
           },
           "Action": "sts:AssumeRole"
         }
       ]
     })


def get_or_create_group(client, name):
    response = client.list_groups()

    groups_by_name = {x["GroupName"]: x for x in response.get("Groups", [])}

    if name not in groups_by_name:
        response = client.create_group(GroupName=name)

        groups_by_name[name] = response.get("Policy")

    return groups_by_name[name]


def update_or_create_policy(client, name, policy):
    response = client.list_policies()

    policy_by_name = {x["PolicyName"]: x for x in response.get("Policies", [])}

    if name not in policy_by_name:
        response = client.create_policy(
            PolicyName=name,
            PolicyDocument=json.dumps(policy),
        )

        policy_by_name[name] = response.get("Policy")
    else:
        response = client.create_policy_version(
            PolicyArn=policy_by_name[name]["Arn"],
            PolicyDocument=json.dumps(policy),
            SetAsDefault=True,
        )

    return policy_by_name[name]


def get_or_create_role(client, name, description,
                       policy_arn=None, trust_arn=None):

    response = client.list_roles()
    roles_by_name = {x["RoleName"]: x for x in response.get("Roles", [])}

    if name not in roles_by_name:
        response = client.create_role(
            RoleName=name,
            Description=description,
            MaxSessionDuration=10800,  # 3 hours
            AssumeRolePolicyDocument=_build_assume_role_policy([trust_arn]),)

        roles_by_name[name] = response.get("Role")

    if policy_arn:
        client.attach_role_policy(
            PolicyArn=policy_arn,
            RoleName=name,
        )

    return roles_by_name[name]


def attach_group_policy(client, group, policy):
    client.attach_group_policy(
        GroupName=group,
        PolicyArn=policy,
    )
