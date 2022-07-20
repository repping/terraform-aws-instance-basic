# This modules deploys a single ec2 instance in AWS that is accessable from the Internet with SSH.

# TODO OS:  Change default user for security
# TODO TF:  Better use of variables!
# TODO TF:  modularize! this is an ec2 module!  example: main.tf calls this modules + the terrafrom.aws.vault-simple module and turns it into a singel deployment.
# TODO TF:  Testen zonder Route table en iGW, zou niet nodig moeten zijn. Maar wel behouden voor toekomst of achter een boolean.
# TODO TF:  Fix ami filter + make var
# TODO AWS: Make Local or var for the AWS Name tags? some pattern seems to repeat :)
# TODO SG:  Make a dynamic cidr block for the ssh SG so it gets ip from where its being deployed every time? 
# TODO SSH: Setup automatic fingerprinting to prevent man in middle attack and annoyance when connecten :)
# TODO DNS: public dns?


# Versioning
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
  }

  required_version = ">= 0.14.9"
}


# Providers
provider "aws" {
  profile = "default"
  region  = var.default_region
}

provider "local" {
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Test VPC Richarde"
  }
}


# single subnet for the ec2 instance to be placed in, AZ irrelevant
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Test subnet Richarde"
  }
}


# internet gateway to allow ssh from the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Test iGW richarde"
  }
}


# route table to route ssh from the internet to the right subnet within the vpc
resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id

  route {
    gateway_id = aws_internet_gateway.gw.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "Test route-table richarde"
  }
}


# Associate the route table with the public subnet of the EC2 instance within the VPC
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main_public.id
}


# Create RSA key of size 4096 bits
resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


# Write ssh private key to local
resource "local_sensitive_file" "private_sshkey" {
  content  = tls_private_key.ec2_ssh_key.private_key_openssh
  filename = "tmp/ec2_ssh_key"
}


# Place ssh pub key in AWS
resource "aws_key_pair" "public_sshkey" {
  key_name   = "ec2_ssh_key"
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh

  tags = {
    Name = "Test ssh key richarde"
  }
}


# Create the AWS instance
resource "aws_instance" "app_server" {
  ami             = "ami-0b0bf695cabdc2ce8"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.main.id]
  subnet_id       = aws_subnet.main.id
  key_name        = aws_key_pair.public_sshkey.key_name

  # Default connection to use for all provisioners.
  connection {
    type        = "ssh"
    user        = var.default_ssh_user
    private_key = local_sensitive_file.private_sshkey.content
    host        = self.public_ip
  }

  provisioner "remote-exec" { # TODO userdata is mooier want platform manier van provisioning
    inline = [
      "echo debugging message to test provisioning",
    ]
  }

  tags = {
    Name = var.instance_name
  }
}


# Create SG with 22 inbound open for ssh and allow all outbound
resource "aws_security_group" "main" {
  name        = "main-sg"
  description = "SG ingress ssh and all outbound"
  vpc_id      = aws_vpc.main.id

  ingress = [{
    description      = "ingress port 22 allow"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["87.101.0.75/32"] # Your current ip, or change to 0.0.0.0/0 to allow all
    self             = true
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
  }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "egress allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
  }]

  tags = {
    Name = "Test SG Richarde"
  }
}