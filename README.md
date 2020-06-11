# IACP-POC-AWS

This installs IaCP for a POC on AWS, currently on a single server.

The following options are available.

* Use the latest marketplace AMI or a user specified AMI
* Alllow the tmeplate to select the subnet or specify a subnet
* Works for private and public subnets, user must set "public = treu/false"
  * Note: subnet must have a gateway to the internet to be able to pull the insallation package
* A self-signed cert is generated by the template and added to the Scalr config. User can replace with their own cert after installation.
* Set a prefix for the instance name

User can choose OS from:

* ubuntu-16.04
* centos-7
* centos-8
* rhel-7
* rhel-8
* amazon-2

Template is designed to be run from the CLI.

1. Clone the repo
1. Put the license file in ./license/license.json
1. Put your private SSH key file in ./ssh/id_rsa. This shoudl be the private part of the key that will be added to the instance (var.ssh_key_name). Required by Terraform to run the installtion scripts.
1. Ensure you have uploaded the public half of the SSH key to AWS.
4. Set variable values to terraform.tfvars
  1. AMI: Either set linux_type to get latest AMI from the AWS market place, OR set ami and ami_owner to use a specific AMI
  2. Subnet is optional
  3. server_count can be ignored. Included for future use.
5. Run `terraform apply`


