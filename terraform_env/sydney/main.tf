terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Call the reusable networking module (dual-AZ)
module "networking" {
  source = "../../terraform_module/networking"

  name     = "study-syd"
  vpc_cidr = "10.0.0.0/16"

  az_a = "ap-southeast-2a"
  az_b = "ap-southeast-2b"

  public_subnet_cidr_a  = "10.0.1.0/24"
  public_subnet_cidr_b  = "10.0.2.0/24"
  private_subnet_cidr_a = "10.0.11.0/24"
  private_subnet_cidr_b = "10.0.12.0/24"
}

# Call the ALB module — 公网入口 + Target Group + 安全组
module "alb" {
  source = "../../terraform_module/alb"

  name              = "study-syd"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}

# Call the EC2 module — 放进 private 子网,挂到 ALB 的 Target Group
module "ec2" {
  source = "../../terraform_module/ec2"

  name                  = "study-syd"
  vpc_id                = module.networking.vpc_id
  private_subnet_id     = module.networking.private_subnet_ids[0]
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}