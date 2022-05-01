variable "name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
}

variable "k8s_version" {
  description = "Kubernetes version."
}

variable "vpc_id" {
  description = "The VPC the cluser should be created in"
}

variable "private_subnets" {
  description = "List of private subnet IDs"
}

variable "public_subnets" {
  description = "List of private subnet IDs"
}

variable "kubeconfig_path" {
  description = "Path where the config file for kubectl should be written to"
}

variable "workernode_instance_types" {}

variable "accountid"{}

variable "app_frontend_secrets"{}

variable "docs_main_user" {}

variable "hybrid_api_dev_secret" {}

variable "docs_admin_user" {}

variable "pw-dev-secret" {}

variable "kyc_docs_bucket" {}

variable "locked_buckets" {}