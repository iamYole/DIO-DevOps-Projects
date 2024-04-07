terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "networking" {
  source = "./Modules/networking"

  tooling_record  = var.tooling_record //module.security.tooling_record
  int-alb-sg_id   = module.security.int-alb-sg_id
  ext-alb-sg_id   = module.security.ext-alb-sg_id
  certificate_arn = module.security.certificate_arn

  vpc_cidr             = local.vpc_cidr
  enable_dns_support   = local.enable_dns_support
  enable_dns_hostnames = local.enable_dns_support
  tag_prefix           = local.tag_prefix
  tags                 = local.tags

  preferred_number_of_private_subnets = local.preferred_number_of_private_subnets
  preferred_number_of_public_subnets  = local.preferred_number_of_public_subnets
}

module "asg" {
  source = "./Modules/ASG"

  bastion_sg-id   = module.security.bastion_sg-id
  nginx_sg-id     = module.security.nginx_sg-id
  webserver_sg-id = module.security.webserver_sg-id

  private_subnets  = module.networking.private_subnets
  public_subnets   = module.networking.public_subnets
  tooling_tg-arn   = module.networking.tooling_tg-arn
  wordpress_tg-arn = module.networking.wordpress_tg-arn
  nginx_tg-arn     = module.networking.nginx_tg-arn


  keypair = var.keypair

  tag_prefix = local.tag_prefix
  tags       = local.tags
}
module "efs" {
  source = "./Modules/EFS"

  datalayer-sg_id = module.security.datalayer-sg_id
  private_subnets = module.networking.private_subnets
  tag_prefix      = local.tag_prefix
  tags            = local.tags
}
module "rds" {
  source = "./Modules/RDS"

  private_subnets = module.networking.private_subnets
  public_subnets  = module.networking.public_subnets
  datalayer-sg_id = module.security.datalayer-sg_id

  db_name         = var.db_name
  master-username = var.master-username
  master-password = var.master-password

  tag_prefix = local.tag_prefix
  tags       = local.tags
}
module "security" {
  source = "./Modules/Security"

  vpc_id           = module.networking.vpc_id
  ext-alb_dns_name = module.networking.alb_dns_name
  ext-alb_zone_id  = module.networking.ext-alb_zone_id

  domain_name      = var.domain_name
  hosted_zone      = var.hosted_zone
  tooling_record   = var.tooling_record
  wordpress_record = var.wordpress_record
  tag_prefix       = local.tag_prefix
  tags             = local.tags
}
