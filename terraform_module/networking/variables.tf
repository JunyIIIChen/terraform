variable "name" {
  description = "Name prefix applied to all networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# --- Availability Zones (dual-AZ / two fixed AZs) ---
variable "az_a" {
  description = "First availability zone"
  type        = string
}

variable "az_b" {
  description = "Second availability zone"
  type        = string
}

# --- Public subnet CIDRs (one per AZ, must be within the VPC CIDR) ---
variable "public_subnet_cidr_a" {
  description = "CIDR block for the public subnet in az_a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for the public subnet in az_b"
  type        = string
  default     = "10.0.2.0/24"
}

# --- Private subnet CIDRs (one per AZ, must be within the VPC CIDR) ---
variable "private_subnet_cidr_a" {
  description = "CIDR block for the private subnet in az_a"
  type        = string
  default     = "10.0.11.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for the private subnet in az_b"
  type        = string
  default     = "10.0.12.0/24"
}