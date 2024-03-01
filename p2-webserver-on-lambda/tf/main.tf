provider "aws" {
  region = "us-west-2"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  backend "s3" {
    bucket = "dx2-tf-state"
    key    = "p2-webserver-on-lambda"
    region = "us-west-2"
  }
}

terraform {

}

variable "super_secret_name" {
  type = string
}
