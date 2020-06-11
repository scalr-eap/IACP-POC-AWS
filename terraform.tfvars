# "Paste in the packagecloud.io token that came with your license file."
token = "{token}"

# "The AWS Region to deploy in"
region = "us-east-1"

# "The variant of linux to be used. Latest AWS Marketplace AMI will be used. Can be overridden with ami input. Values are ubuntu-16.04, centos-7, centos-8, rhel-7, rhel-8, amazon-2"
linux_type = "ubuntu-16.04"

# "Specifc AMI to use. Overrides linux_type"
ami = ""

# "Owner of the ami if ami is specified"
ami_owner = "aws-marketplace"

# "Instance type must have minimum of 16GB ram and 50GB disk"
instance_type = "t3.xlarge"

# "Indicates if Public IP/DNS will be used to access Scalr"
public = true

# "The name of then public SSH key to be deployed to the servers. This must exist in AWS already"
ssh_key_name = "{key-name}"

# "The VPC to be used. Instance will be allocated to first subnet unless subnet is also set"
vpc = "{vpc-id}"

# "(optional) Set a specific subnet. If left blank the first subnet in the VPC will be used"
subnet = ""

# "1-3 char prefix for instance names
name_prefix = "{prefix}"

