variable "token" {
  description = "Paste in the packagecloud.io token that came with your license file."
  type = string
}

variable "region" {
  description = "The AWS Region to deploy in"
  type = string
}

variable "linux_type" {
  description = "The variant of linux to be used. Latest AWS Marketplace AMI will be used. Can be overridden with ami input. Values are ubuntu-16.04, centos-7, centos-8, rhel-7, rhel-8, amazon-2"
  type = string
}

variable "ami" {
  type = string
  description = "Specifc AMI to use. Overrides linux_type if set"
}

variable ami_owner {
  type = string
  description = "Owner of the ami if ami is specified"
}

variable "instance_type" {
  description = "Instance type must have minimum of 16GB ram and 50GB disk"
  type = string
}

variable "public" {
  type = bool
  description = "Indicates if Public IP/DNS will be used to access Scalr"
}

variable "ssh_key_name" {
  description = "The name of then public SSH key to be deployed to the servers. This must exist in AWS already"
  type = string
}

variable "vpc" {
  type = string
  description = "The VPC to be used. Instance will be allocated to first subnet unless subnet is also set"
}

variable "subnet" {
  type = string
  description = "(optional) Set a specific subnet. If left blank the first subnet in the VPC will be used"
  default = ""
}

variable "name_prefix" {
  description = "1-3 char prefix for instance names"
  type = string
}

variable "tags" {
  type = map
  description = "Add a map of tags (key = value) to be added to the deployed resources."
  default = {}
}

variable server_count {
  type = number
  description = "Number of Scalr servers to run. Currentkly max = 1"
  default = 1
}
