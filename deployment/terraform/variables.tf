variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project, used for tagging and naming resources."
  type        = string
  default     = "drl-portfolio"
}

variable "environment" {
  description = "The deployment environment (e.g., staging, production)."
  type        = string
  default     = "staging"
}
