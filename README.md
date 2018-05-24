# Boot you some AWS


This is an attempt to encode some best practices about booting an AWS setup.

## End Result

You'll end up with the following.

- A root account
  - Configured with an s3 bucket for state
  - A DynamoDB table ofr state lock

## Instructions

## Create an AWS Account

This first account will be your root account. This root account will be the parent of all your other accounts. It will contain very little.

Start by creating an account, use strong credentials. Store them securely.

Next create an an admin account, and generate an aws IAM access key and secret.

Export those as environment variables.

You are now ready to start configuring your account.

## Establish Organizations

The first step is to establish organizations.

```
make setup_organizations
```

This will output variables into your root folder.

## Establish root state

Becase we use terraform, we need a way to keep remote state.

```
make root_state_init
```

Then we are going to apply which will create
