terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket       = "sctp-ce12-tfstate-bucket"
    key          = "ecs/default/terraform.tfstate"
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
