variable "instance_name" {
  description = "Variable waarde om de instance name te zetten in de AWS webgui."
  type        = string
  default     = "Test ec2 instance richarde"
}

variable "default_region" {
  description = "Default region where the resources will be deployed."
  type        = string
  default     = "eu-west-1"
}

variable "default_ssh_user" {
  description = "Default user of the ami used"
  type        = string
  default     = "ec2-user"
}

variable "default_ssh_key" {
  description = "default location and filename of the private ssh key"
  type        = string
  default     = "tmp/ec2_ssh_key"
}