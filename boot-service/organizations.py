import logging
import pprint
import boto3

import api

from consts import OUS

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    org_client = boto3.client('organizations')
    sts_client = boto3.client('sts')

    # Get or build organization
    # There is only one per account
    organization = api.build_root_org(org_client)

    # We are going to have all our OUs underneath
    # the root for now. So, first we need to find
    # the id of the root.
    root = api.find_root(org_client)

    ous_by_name = api.get_ous_by_name(org_client, root)
    # Next we are going to establish a user OU
    user_ou = api.get_or_create_ou(org_client, OUS.USER.NAME, root, ous_by_name)
    environment_ous = {}
    for env, env_ou in OUS.ENVIRONMENTS.items():
        environment_ous[env] = api.get_or_create_ou(
            org_client, env_ou.NAME, root, ous_by_name)

    # Find exisisting policieis
    policies_by_name = api.get_policies_by_name(org_client)

    # Establish a users ou policy
    api.get_or_create_ou_policy(org_client, policies_by_name,
                         OUS.USER.POLICY_NAME, OUS.USER.POLICY_CONTENT)
    for env, env_ou in OUS.ENVIRONMENTS.items():
        api.get_or_create_ou_policy(org_client, policies_by_name,
                             env_ou.POLICY_NAME, env_ou.POLICY_CONTENT)

    # Enable SERVICE_CONTROL_POLICIES
    api.enable_policies(org_client, root)

    # Attach policy to users ou
    api.attach_policy(
        org_client,
        policies_by_name[OUS.USER.POLICY_NAME],
        ous_by_name[OUS.USER.NAME])

    for env, env_ou in OUS.ENVIRONMENTS.items():
        api.attach_policy(
            org_client,
            policies_by_name[env_ou.POLICY_NAME],
            ous_by_name[env_ou.NAME])

    # Here we want to detach the default polycy that allows
    # child orgs to do everything. Because we want to finely
    # control what orgs can do.
    api.detach_aws_policy(org_client, ous_by_name[OUS.USER.NAME])
    for env, env_ou in OUS.ENVIRONMENTS.items():
        api.detach_aws_policy(org_client, ous_by_name[env_ou.NAME])

    accounts_by_name = api.get_accounts_by_name(org_client)

    api.create_root_account_in_ou(org_client, OUS.USER.EMAIL, OUS.USER.ROOT_NAME)
    for env, env_ou in OUS.ENVIRONMENTS.items():
        api.create_root_account_in_ou(org_client, env_ou.EMAIL, env_ou.ROOT_NAME)

    users_ou_root_account = accounts_by_name[OUS.USER.ROOT_NAME]
    api.move_account_to_ou(org_client, users_ou_root_account, root, user_ou)
    for env, env_ou in OUS.ENVIRONMENTS.items():
        account = accounts_by_name[env_ou.ROOT_NAME]
        ou = ous_by_name[env_ou.NAME]
        api.move_account_to_ou(org_client, account, root, ou)

    # Establish the role in the users OU that allows users to assume roles
    # In other OUs
    # users_iam_client = api.get_client_for_account(
    #     sts_client, users_ou_root_account, "iam")
    #
    # group = api.get_or_create_group(
    #     users_iam_client,
    #     'Admins',
    # )
    #
    #
    # for env, env_ou in OUS.ENVIRONMENTS.items():
    #     account = accounts_by_name[env_ou.ROOT_NAME]
    #     iam_client = api.get_client_for_account(
    #         sts_client, account, "iam")
    #
    #     role = api.get_or_create_role(
    #         iam_client,
    #         'UsersAdminRole',
    #         'This role allows you to administer everything in this account',
    #         "arn:aws:iam::aws:policy/AdministratorAccess",
    #         "arn:aws:iam::%s:root" % (users_ou_root_account["Id"]),
    #     )
    #     print("A role")
    #     pprint.pprint(iam_client.list_role_policies(RoleName="UsersAdminRole"))
    #
    #
    # identifiers = []
    # for env, env_ou in OUS.ENVIRONMENTS.items():
    #     account = accounts_by_name[env_ou.ROOT_NAME]
    #     identifiers += [
    #         "arn:aws:iam::%s:role/UsersAdminRole" % (account['Id'])
    #     ]
    #
    # policy = api.update_or_create_policy(
    #     users_iam_client,
    #     'AdminToAdminRolePolicy',
    #     {
    #        "Version": "2012-10-17",
    #        "Statement": [{
    #            "Effect": "Allow",
    #            "Action": "sts:AssumeRole",
    #            "Resource": identifiers,
    #         }, {
    #             "Effect": "Allow",
    #             "Action": [
    #                "iam:ChangePassword",
    #                "iam:CreateAccessKey",
    #                "iam:CreateLoginProfile",
    #                "iam:DeleteAccessKey",
    #                "iam:DeleteLoginProfile",
    #                "iam:GetLoginProfile",
    #                "iam:ListAccessKeys",
    #                "iam:UpdateAccessKey",
    #                "iam:UpdateLoginProfile",
    #                "iam:ListSigningCertificates",
    #                "iam:DeleteSigningCertificate",
    #                "iam:UpdateSigningCertificate",
    #                "iam:UploadSigningCertificate",
    #                "iam:ListSSHPublicKeys",
    #                "iam:GetSSHPublicKey",
    #                "iam:DeleteSSHPublicKey",
    #                "iam:UpdateSSHPublicKey",
    #                "iam:UploadSSHPublicKey"
    #             ],
    #             "Resource": "arn:aws:iam::%s:user/${aws:username}" % (
    #                 users_ou_root_account["Id"])
    #         }]
    #     }
    # )
    #
    # api.attach_group_policy(users_iam_client, "Admins", policy["Arn"])

    print("Information for terraform")
    print("users ou account_id: %s" % (users_ou_root_account["Id"]))
    for env, env_ou in OUS.ENVIRONMENTS.items():
        print("%s ou account_id: %s" % (
            env,
            accounts_by_name[env_ou.ROOT_NAME]["Id"]
        ))
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
