variable "aws_region" {
  description = "The AWS region where the EKS cluster is deployed."
  default     = "us-east-1"
}

variable "datadog_api_key" {
  description = "Your Datadog API key."
  type        = string
}

variable "datadog_app_key" {
  description = "Your Datadog Application key."
  type        = string
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "db_username" {
  type        = string
  description = "PostgreSQL database username."
  default     = "dbadmin"
}

variable "db_password" {
  type        = string
  description = "PostgreSQL database password."
  sensitive   = true
}