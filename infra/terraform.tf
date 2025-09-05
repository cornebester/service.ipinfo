terraform {
  required_version = "~> 1.10.5" # << NB update CI runner version in Github action !!!

  required_providers {
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source = "hashicorp/aws"
      # version = "~> 5.86.0" #  >= 5.47.0
    }
    # https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  # profile = var.aws_profile
  #version = "~> 1.0"

  default_tags {
    tags = {
      # Environment = "Test"
      Owner = "corne"
      # Project     = "Test"
      ManagedBy = "terraform"
    }
  }
}
