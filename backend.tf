
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.18.0"
    }
  }
  backend "s3" {
    bucket         = "aparna-2tier-bucket"
    key            = "global/tfstate"
    region         = "us-east-1"
    dynamodb_table = "email-app-tfstate-bucket"
    encrypt        = true
  }
}