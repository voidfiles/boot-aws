import logging
import pprint
import boto3
import json
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

    output_data = {
        "root_account_id": sts_client.get_caller_identity().get("Account"),
        "users_account_id": users_ou_root_account["Id"],
        "environment_account_ids": {},
        "root_id": "boot",
        "internal_domain": "brntgarlic.com",
    }

    for env, env_ou in OUS.ENVIRONMENTS.items():
        output_data['environment_account_ids'][env_ou.NAME] = accounts_by_name[env_ou.ROOT_NAME]["Id"]

    print(json.dumps(output_data, indent=4, sort_keys=True))
