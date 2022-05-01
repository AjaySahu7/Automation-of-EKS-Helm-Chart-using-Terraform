variable "app_domain_name" {
  type = list
}

variable "bastion_domain_name" {
  type = string
}
variable "vpc_id" {}
variable "hostname" {
  default = "bastion"
}

variable "private_ip" {
  description = "Private ip of bastion host"
}