
# NovaPay Kubernetes cluster infrastructure - illustrative module
# Provisions the EKS cluster and supporting resources referenced across all deliverables

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for NovaPay infrastructure"
  type        = string
  default     = "ap-south-1" # Mumbai - low latency for Indian banking traffic
}

variable "environment" {
  description = "Deployment environment: dev, staging, pre-prod, production"
  type        = string
}

resource "aws_eks_cluster" "novapay" {
  name     = "novapay-${var.environment}"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.environment != "production" # prod: private access only
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Compliance  = "rbi-pci-dss"
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "novapay-eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}
