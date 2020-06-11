#terraform {
#  backend "remote" {
#    hostname = "my.scalr.com"
#    organization = "org-sfgari365m7sck0"
#    workspaces {
#      name = "iacp-ha-install"
#    }
#  }
#}


locals {
  ssh_private_key_file = "./ssh/id_rsa"
  license_file         = "./license/license.json"

  # Currently forces server_count = 1. When multiple servers allowed will limit to the number of subnets
  server_count         = min(length(data.aws_subnet_ids.scalr_ids),var.server_count,1)
}

locals {
  linux_types = [ 
    "ubuntu-16.04",
    "centos-7",
    "centos-8",
    "rhel-7",
    "rhel-8",
    "amazon-2"
   ]
  names = [ 
    "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*",
    "CentOS Linux 7 x86_64*",
    "SupportedImages CentOS Linux 8 x86_64*",
    "SupportedImages RHEL-7.*",
    "SupportedImages RHEL-8.*",
    "amzn2-ami-hvm-2.0*"
   ]
  owners = [ 
    "099720109477", #CANONICAL
    "679593333241",
    "679593333241",
    "679593333241",
    "679593333241",
    "amazon"
    ]
  users = [
    "ubuntu",
    "centos",
    "centos",
    "ec2-user",
    "ec2-user",
    "ec2-user"
  ]
}

provider "aws" {
    region     = var.region
}

# Obtain the AMI for the region

data "aws_ami" "the_ami" {
  most_recent = true

  filter {
    name   = var.ami != "" ? "image-id" : "name"
    values = [var.ami != "" ? var.ami : element(local.names,index(local.linux_types,var.linux_type))]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = [var.ami != "" ? var.ami_owner : element(local.owners,index(local.linux_types,var.linux_type))] 
}

data "aws_subnet_ids" "scalr_ids" {
  vpc_id = var.vpc
}

###############################
#
# Scalr Server
#

resource "aws_instance" "iacp_server" {
  count                   = local.server_count
  ami                     = data.aws_ami.the_ami.id
  instance_type           = var.instance_type
  key_name                = var.ssh_key_name
  vpc_security_group_ids  = [ data.aws_security_group.default_sg.id, aws_security_group.scalr_sg.id ]
  subnet_id               = var.subnet != "" ? var.subnet : element(tolist(data.aws_subnet_ids.scalr_ids.ids),count.index)

  tags = merge(
    map( "Name", "${var.name_prefix}-iacp-server-${tostring(count.index)}"),
    var.tags )
  
  connection {
        host	= self.public_ip
        type     = "ssh"
        user     = element(local.users,index(local.linux_types,var.linux_type))
        private_key = file(local.ssh_private_key_file)
        timeout  = "20m"
  }

  provisioner "file" {
        source = local.license_file
        destination = "/var/tmp/license.json"
  }

  provisioner "file" {
      source = "./SCRIPTS/scalr_install.sh"
      destination = "/var/tmp/scalr_install.sh"
  }

}

resource "aws_ebs_volume" "iacp_vol" {
  count                   = local.server_count
  availability_zone       = aws_instance.iacp_server[count.index].availability_zone
  type                    = "gp2"
  size                    = 50

  tags = var.tags
}

resource "aws_volume_attachment" "iacp_attach" {
  count                   = local.server_count
  device_name             = "/dev/sds"
  instance_id             = aws_instance.iacp_server[count.index].id
  volume_id               = aws_ebs_volume.iacp_vol[count.index].id
}

## Certificate

resource "tls_private_key" "scalr_pk" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "scalr_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.scalr_pk.private_key_pem

  subject {
    common_name  = var.public == true ? aws_instance.iacp_server.0.public_dns : aws_instance.iacp_server.0.private_dns
    organization = "Scalr"
  }

  validity_period_hours = 336

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "null_resource" "null_1" {
  depends_on = [aws_instance.iacp_server]
  count                   = local.server_count

  connection {
        host	= aws_instance.iacp_server[count.index].public_ip
        type     = "ssh"
        user     = element(local.users,index(local.linux_types,var.linux_type))
        private_key = file(local.ssh_private_key_file)
        timeout  = "20m"
  }

  provisioner "file" {
        content     = tls_self_signed_cert.scalr_cert.cert_pem
        destination = "/var/tmp/my.crt"
  }

  provisioner "file" {
        content     = tls_private_key.scalr_pk.private_key_pem
        destination = "/var/tmp/my.key"
  }
  provisioner "remote-exec" {
      inline = [
        "chmod +x /var/tmp/scalr_install.sh",
        "sudo /var/tmp/scalr_install.sh '${var.token}' ${aws_volume_attachment.iacp_attach[count.index].volume_id} ${var.public == true ? aws_instance.iacp_server[count.index].public_dns : aws_instance.iacp_server[count.index].private_dns}"
      ]
  }

}

resource "null_resource" "get_info" {

  depends_on = [null_resource.null_1 ]
  count                   = local.server_count
  connection {
        host	= aws_instance.iacp_server[count.index].public_ip
        type     = "ssh"
        user     = element(local.users,index(local.linux_types,var.linux_type))
        private_key = file(local.ssh_private_key_file)
        timeout  = "20m"
  }

  provisioner "file" {
      source = "./SCRIPTS/get_pass.sh"
      destination = "/var/tmp/get_pass.sh"

  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/get_pass.sh",
      "sudo /var/tmp/get_pass.sh",
    ]
  }

}

output "dns_name" {
  value = aws_instance.iacp_server.*.public_dns
}
output "scalr_iacp_server_public_ip" {
  value = aws_instance.iacp_server.*.public_ip
}


