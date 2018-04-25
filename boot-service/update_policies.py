import logging

import boto3
import json

from botocore.exceptions import ClientError

from consts import OUS

logger = logging.getLogger(__name__)


if __name__ == "__main__":
    org_client = boto3.client('organizations')

    response = org_client.list_policies(
        Filter='SERVICE_CONTROL_POLICY',
    )
    policies_by_name = {x["Name"]: x for x in response.get("Policies", [])}

    response = org_client.update_policy(
        PolicyId=policies_by_name[OUS.USER.POLICY_NAME]["Id"],
        Content=json.dumps(OUS.USER.POLICY_CONTENT),
    )
