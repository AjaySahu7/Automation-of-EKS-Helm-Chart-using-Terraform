variable "name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\"" 
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both private_subnets and public_subnets have to be defined as well"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
}

variable "private_subnets" {
  description = "a list of CIDRs for private subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
}

variable "public_subnets" {
  description = "a list of CIDRs for public subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
}

variable "kubeconfig_path" {
  description = "Path where the config file for kubectl should be written to"
}

variable "k8s_version" {
  description = "kubernetes version"
  default     = ""
}

variable "key_name" {}

variable "bastion_instance_type" {
  type        = string
  description = "instance type for bastion host"
}

variable "twingate_instance_type" {
  type        = string
  description = "instance type for twingate connectors"
}

variable "twingate_connectors" {
  type = map(object({
    private_subnet_index = number
  }))
  description = "Map of twingate connector names to settings"
}

variable "twingate_tokens" {
  type = map(object({
    access_token  = string
    refresh_token = string
  }))
  description = "Map of twingate secret tokens by connector name"
  sensitive = true
}

variable "db_instance_type" {}
variable "workernode_instance_types" {}
variable "ecr_name" {}
variable "repository" {}
variable "account_id" {}

variable "secret_manager_arn" {
  type = string
  description = "Fill the secret amazon resource name (arn) you gave to your secret"
}

variable "banking_server_kyc_docs_bucket" {
  type = string
}

variable "banking_server_locked_buckets" {
  type = map(object({
    retention_days = number
  }))
  description = "Locked buckets for the banking server"
}

variable "app_frontend_secrets"{}

variable "docs_main_user" {}

variable "hybrid_api_dev_secret" {}

variable "docs_admin_user" {}

variable "pw-dev-secret" {}

#Route53
variable "app_domain_name" {
  type = list
  description = "Provide Application Domain name"
}

variable "bastion_domain_name" {
  type = string
  description = "Provide Bastion Domain name"
}
