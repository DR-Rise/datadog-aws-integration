variable "aws_region" {
  description = "The AWS region where the EKS cluster is deployed."
  default     = "us-west-2"
}

variable "datadog_api_key" {
  description = "Your Datadog API key."
  type        = string
}

variable "datadog_app_key" {
  description = "Your Datadog Application key."
  type        = string
}

variable "nodejs_image" {
  description = "The Docker image for your Node.js application."
  type        = string
}
variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}
