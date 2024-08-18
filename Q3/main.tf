provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "kubernetes" {
  config_path = "C:/Users/driss/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "C:/Users/driss/.kube/config"
    host        = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "education-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "education-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
      addon_version            = "v1.29.1-eksbuild.1"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

# Add missing data sources for EKS cluster and authentication
data "aws_eks_cluster" "main" {
  depends_on = [module.eks]  # Ensure the cluster is created before this data block runs
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  depends_on = [module.eks]  # Ensure the cluster is created before this data block runs
  name       = module.eks.cluster_name
}

# AWS IAM Policy for EBS CSI Driver
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# IRSA (IAM Role for Service Account) for EBS CSI Driver
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "helm_release" "datadog" {
  depends_on = [module.eks]

  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  version    = "3.69.3"
  namespace  = "default"

  values = [
    file("./datadog-values.yaml")
  ]
}



resource "aws_db_instance" "postgres" {
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "13.16"
  instance_class          = "db.t3.small"
  identifier              = "my-database"
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = "default.postgres13"
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet.name
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet_group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "rds_subnet_group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_security_group"
  description = "Allow traffic from Datadog agents for PostgreSQL monitoring"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Restrict this to your private subnet or specific CIDR blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

