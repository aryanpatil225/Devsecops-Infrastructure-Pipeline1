# ─────────────────────────────────────────────────────
# WHY specify terraform version?
# Prevents unexpected behavior if someone runs with
# an older/newer Terraform version.
# Locks everyone to the same version = consistent.
# ─────────────────────────────────────────────────────
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─────────────────────────────────────────────────────
# WHY no credentials here?
# NEVER hardcode AWS keys in Terraform files.
# These files go to GitHub — exposed keys = hacked account.
#
# Credentials come from:
# Option 1: Environment variables (AWS_ACCESS_KEY_ID etc.)
# Option 2: AWS CLI config (~/.aws/credentials)
# Option 3: IAM Role (best for production)
#
# We will use AWS CLI config for this project.
# ─────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devsecops-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "devsecops-engineer"
    }
  }
}