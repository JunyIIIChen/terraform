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

module "hello_world" {
  source = "../../terraform_module/lambda"

  name = "study-syd-hello-world"
}

output "function_name" {
  value = module.hello_world.function_name
}

output "function_arn" {
  value = module.hello_world.function_arn
}
