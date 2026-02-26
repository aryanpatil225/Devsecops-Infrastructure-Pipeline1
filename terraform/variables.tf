# ─────────────────────────────────────────────────────
# WHY variables?
# No hardcoded values anywhere in Terraform.
# Change one variable = changes everywhere it's used.
# Makes code reusable across environments.
# ─────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  # WHY us-east-1? Most free-tier services available here
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "demo"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "devsecops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  # WHY /16? Gives us 65,536 IP addresses
  # Plenty of room to add more subnets later
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
  # WHY /24? Gives us 256 IPs for this subnet
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  # WHY t2.micro?
  # FREE TIER eligible = 750 hours/month FREE
  # Perfect for demo — costs $0
}

variable "availability_zone" {
  description = "Availability zone for subnet"
  type        = string
  default     = "us-east-1a"
}