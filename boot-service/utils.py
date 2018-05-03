from collections import namedtuple


class PolicyStatement(object):
    def __init__(self, effect="ALLOW", actions=None,
                 principals=None, resources="*"):
        self.effect = effect
        self.actions = actions
        self.principals = principals
        self.resources = resources

    def to_dict(self):
        value = {
            "Effect": self.effect,
        }

        if self.actions:
            value["Action"] = self.actions


def generate_policy(statements):
    return {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": s.effect,
        "Action": s.actions,
        "Resource": s.resources,
      } for s in statements]
    }
