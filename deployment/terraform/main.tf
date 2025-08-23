terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Best practice: Use a remote backend to store the Terraform state file securely and centrally.
  # This needs to be configured with a pre-existing S3 bucket and DynamoDB table for locking.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
