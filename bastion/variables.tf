variable "name" {
  description = "Name of the project"
}

variable "environment" {
  description = "Environment Type"
}

variable "key_name" {
  description = "Private key"
}

variable "instance_type" {
  description = "Backend-Prod server type"
}
variable "vpc" {
  type        = string
  description = "vpc"
}

variable "public_subnet_id" {}
variable "secret_manager_arn" {}
variable "aws_region" {}
variable "RDS-Endpoint"{}
variable "rds" {}

variable "app_namespace" {
  type = string
}

variable "bank_namespace" {
  type = string
}

variable "app-service-account" {}

variable "bank-service-account" {}