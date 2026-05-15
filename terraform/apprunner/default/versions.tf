terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket       = "capstone-project-group5"
    key          = "apprunner/default/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
}
