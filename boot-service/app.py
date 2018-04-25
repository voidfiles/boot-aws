import logging

import pprint

import boto3

from botocore.exceptions import ClientError

from consts import OUS

logger = logging.getLogger(__name__)



def email_maker(namespace):
    return "voidfiles+boot-%s@gmail.com" % (namespace)


def get_client_for_role(client_type, role):
    credentials = role['Credentials']

    return boto3.client(
        client_type,
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
    )


if __name__ == "__main__":
    org_client = boto3.client('organizations')
    sts_client = boto3.client('sts')

    # Get or build organization
    # There is only one per account
    response = org_client.describe_organization()
    organization = response.get("Organization")
    if not organization:
        logger.info("Creating an organization")
        response = org_client.create_organization(
            FeatureSet='ALL'
        )

        organization = response.get("Organization")

    # We are going to have all our OUs underneath
    # the root for now. So, first we need to find
    # the id of the root.
    response = org_client.list_roots()
    roots = response.get("Roots", [])
    if not roots:
        raise Exception("Missing a root")

    root = roots[0]

    # Next we are going to establish a user OU
    response = org_client.list_organizational_units_for_parent(
        ParentId=root['Id'],
    )

    ous = response.get("OrganizationalUnits", [])
    ous_by_name = {x["Name"]: x for x in ous}

    user_ou = ous_by_name.get(OUS.USER.NAME)

    if not user_ou:
        logger.info("Creating a users ou: %s", OUS.USER.NAME)
        response = org_client.create_organizational_unit(
            ParentId=root["Id"],
            Name=OUS.USER.NAME
        )
        ous_by_name[OUS.USER.NAME] = response.get("OrganizationalUnit")

    # Find exisisting policieis
    response = org_client.list_policies(
        Filter='SERVICE_CONTROL_POLICY',
    )
    policies_by_name = {x["Name"]: x for x in response.get("Policies", [])}

    # Establish a users ou policy
    if OUS.USER.POLICY_NAME not in policies_by_name:
        logger.info("Creating a users ou policy: %s", OUS.USER.POLICY_NAME)
        response = org_client.create_policy(
            Content=OUS.USER.POLICY_CONTENT,
            Description='A policy for %s' % (OUS.USER.POLICY_NAME),
            Name=OUS.USER.POLICY_NAME,
            Type='SERVICE_CONTROL_POLICY'
        )

        policies_by_name[OUS.USER.POLICY_NAME] = response.get("Policy")

    # Enable the policy
    try:
        response = org_client.enable_policy_type(
            RootId=root['Id'],
            PolicyType='SERVICE_CONTROL_POLICY'
        )
    except ClientError as e:
        if e.response['Error']['Code'] == "PolicyTypeAlreadyEnabledException":
            pass
        else:
            raise

    try:
        response = org_client.attach_policy(
            PolicyId=policies_by_name[OUS.USER.POLICY_NAME]['Id'],
            TargetId=ous_by_name[OUS.USER.NAME]["Id"],
        )
    except ClientError as e:
        if e.response['Error']['Code'] == "DuplicatePolicyAttachmentException":
            pass
        else:
            raise

    response = org_client.create_account(
        Email=email_maker(OUS.USER.ROOT_NAME),
        AccountName=OUS.USER.ROOT_NAME,
        IamUserAccessToBilling='ALLOW'
    )

    # Here we want to detach the default polycy that allows
    # child orgs to do everything. Because we want to finely
    # control what orgs can do.
    response = org_client.list_policies_for_target(
        TargetId=ous_by_name[OUS.USER.NAME]["Id"],
        Filter='SERVICE_CONTROL_POLICY',
    )

    policy_by_name = {x["Name"]: x for x in response.get("Policies", [])}

    if "FullAWSAccess" in policy_by_name:
        response = org_client.detach_policy(
            PolicyId=policy_by_name["FullAWSAccess"]["Id"],
            TargetId=ous_by_name[OUS.USER.NAME]["Id"],
        )

    response = org_client.list_accounts()

    accounts = response.get("Accounts", [])
    accounts_by_name = {x["Name"]: x for x in accounts}
    users_ou_root_account = accounts_by_name[OUS.USER.ROOT_NAME]

    print("Information for terraform")
    print("users ou account_id: %s" % (users_ou_root_account["Id"]))
    # We need this in order to get into the users ou
    # response = org_client.list_accounts()
    #
    # accounts = response.get("Accounts", [])
    # pprint.pprint(accounts)
    # accounts_by_name = {x["Name"]: x for x in accounts}
    # users_ou_root_account = accounts_by_name[OUS.USER.ROOT_NAME]
    # response = sts_client.assume_role(
    #     RoleArn='arn:aws:iam::%s:role/OrganizationAccountAccessRole' % (
    #         users_ou_root_account["Id"]),
    #     RoleSessionName='establsh',
    # )
    # sub_org_client = get_client_for_role("organizations", response)
    # response = sub_org_client.list_handshakes_for_account()
