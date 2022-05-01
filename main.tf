provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./vpc"
  name               = var.name
  environment        = var.environment
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
}
 
module "eks" {
  source                    = "./eks"
  name                      = var.name
  environment               = var.environment
  region                    = var.region
  k8s_version               = var.k8s_version
  vpc_id                    = module.vpc.id
  private_subnets           = module.vpc.private_subnets
  public_subnets            = module.vpc.public_subnets
  kubeconfig_path           = var.kubeconfig_path
  workernode_instance_types = var.workernode_instance_types
  accountid                 = var.account_id
  hybrid_api_dev_secret     = var.hybrid_api_dev_secret
  docs_admin_user           = var.docs_admin_user
  docs_main_user            = var.docs_main_user
  pw-dev-secret             = var.pw-dev-secret
  app_frontend_secrets      = var.app_frontend_secrets
  locked_buckets            = module.banking-server-buckets.locked_buckets
  kyc_docs_bucket           = module.banking-server-buckets.kyc_docs_bucket
}

module "banking-server-buckets" {
  source               = "./banking-server-buckets"
  region               = var.region
  kyc_docs_bucket_name = var.banking_server_kyc_docs_bucket
  locked_buckets       = var.banking_server_locked_buckets
  s3_iam_role_arn      = module.eks.s3_iam_role_arn
}

module "bastion" {
  source               = "./bastion"
  name                 = var.name
  environment          = var.environment
  vpc                  = module.vpc.id
  instance_type        = var.bastion_instance_type
  key_name             = var.key_name
  public_subnet_id     = module.vpc.public_subnets[0].id
  aws_region           = var.region
  secret_manager_arn   = var.secret_manager_arn
  RDS-Endpoint         = module.rds.RDS-Endpoint
  rds                  = module.rds.rds
  app_namespace        = module.eks.app_namespace
  bank_namespace       = module.eks.bank_namespace
  app-service-account  = module.eks.app-service-account
  bank-service-account = module.eks.bank-service-account

}

module "twingate" {
  source              = "./../shared_modules/twingate"
  name                = var.name
  environment         = var.environment
  instance_type       = var.twingate_instance_type
  key_name            = var.key_name
  vpc                 = module.vpc.id
  security_group_ids  = [module.bastion.ec2_sg_group.id]

  for_each            = var.twingate_connectors
  connector_name      = each.key
  access_token        = lookup(var.twingate_tokens, each.key).access_token
  refresh_token       = lookup(var.twingate_tokens, each.key).refresh_token
  subnet_id           = element(module.vpc.private_subnets, each.value.private_subnet_index).id
}

module "rds" {
  source           = "./rds"
  name             = var.name
  environment      = var.environment
  db_instance_type = var.db_instance_type
  secret_manager_arn = var.secret_manager_arn
  ec2_sg_group     = module.bastion.ec2_sg_group
  private_subnets  = module.vpc.private_subnets
  vpc              = module.vpc.id
}

module "helm" {
  source = "./helm"
  cluster_id   = module.eks.cluster_id
}

module "ecr" {
  source = "./ecr"
  ecr_name = var.ecr_name
  account_id = var.account_id
  region = var.region
  repository = var.repository
}

module "route53" {
  source                    = "./route53"
  app_domain_name           = var.app_domain_name
  vpc_id                    = module.vpc.id
  private_ip                = module.bastion.private_ip
  bastion_domain_name       = var.bastion_domain_name
}
