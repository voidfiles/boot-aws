# Boot you some AWS


This is an attempt to encode some best practices about booting an AWS tooling.


## Targets

- A root account dedicated to administration and consolidated billing
  - A s3 bucket for admin state
    - terraform
    - Online intermediate CA keys
    - Online CA public keys
  - DynamoDB table for terraform locking
  - Setting up security control policies for organizational units
- Establishing a Users OU
  - You only need to setup SSO into this OU
  - Users will only need to get one access key and token
- Establish per environment OUs
  - No users exist in these accounts except root accounts
  - Roles that will enable others to do things
  - Each one of these
