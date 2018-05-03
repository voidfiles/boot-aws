# Root

This set of terraform must be run with root credentials in the root OU. You are
probably not going to do that very often.

The goal is to setup just enough cross-account trust that you can then use
non-root credentials in each specific OU to make terraform changes.

But, before you can run this you must make sure you have already run the
boot scripts. Terraform doesn't manage OUs and service control policies. So,
first run that and then you will need to populate some of the variables in this
project.
