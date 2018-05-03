import logging

import boto3

import api
from consts import OUS

logger = logging.getLogger(__name__)


if __name__ == "__main__":
    org_client = boto3.client('organizations')

    response = org_client.list_policies(
        Filter='SERVICE_CONTROL_POLICY',
    )
    policies_by_name = {x["Name"]: x for x in response.get("Policies", [])}

    api.update_policy(
        org_client, policies_by_name[OUS.USER.POLICY_NAME], OUS.USER)

    for env, env_ou in OUS.ENVIRONMENTS.items():
        api.update_policy(
            org_client, policies_by_name[env_ou.POLICY_NAME], env_ou)
