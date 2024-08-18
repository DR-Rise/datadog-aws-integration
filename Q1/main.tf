terraform {
  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = "3.17.0"  
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
}

# IAM Role and Policy for Datadog
resource "aws_iam_role" "datadog_aws_integration" {
  name               = "DatadogAWSIntegrationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::464622532012:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "datadog_aws_integration_policy" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = file("${path.module}/datadog_aws_permissions.json")
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration_attachment" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration_policy.arn
}

# Datadog Integration
resource "datadog_integration_aws" "aws_integration" {
  account_id = var.aws_account_id
  role_name  = aws_iam_role.datadog_aws_integration.name
}
