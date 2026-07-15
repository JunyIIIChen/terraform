variable "name" {
  description = "Name prefix applied to all ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where the ALB and its target group live"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB — must span at least 2 AZs"
  type        = list(string)
}