import os

import json

CWD = os.path.dirname(os.path.realpath(__file__))


def get_or_set(cls, file_name):
    value = getattr(cls, '_POLICY_CONTENT', None)
    if value:
        return value

    data = ""
    with open(CWD + "/data/%s" % (file_name,)) as fd:
        data = fd.read()

    data = json.loads(data)

    cls._POLICY_CONTENT = data

    return data


class UserOUDetails(object):
    NAME = "users"
    POLICY_NAME = "users_ou_policy"
    ROOT_NAME = "users-root"

    @property
    def POLICY_CONTENT(cls):
        return get_or_set(cls, "user_ou_policy.json")


class OUS(object):
    USER = UserOUDetails()
