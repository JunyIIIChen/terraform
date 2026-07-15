variable "name" {
  description = "Name prefix applied to all EC2 resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where the EC2 and its security group live"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID to launch the EC2 into"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB's security group ID — only it is allowed to reach the EC2 on port 80"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN to attach this EC2 to"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type — t2.micro is free-tier eligible"
  type        = string
  default     = "t2.micro"
}
