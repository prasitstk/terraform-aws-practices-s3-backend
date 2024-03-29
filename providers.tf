terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "terraform-backend-<random-string>"
  #   region         = "ap-southeast-1"
  #   key            = "test/remote_terraform.tfstate"

  #   # NOTE: `encrypt = true` as a second layer in addition to `backend_bucket_sse` to ensure that the state file is always encrypted on the S3 bucket.
  #   encrypt        = true

  #   dynamodb_table = "terraform-backend-state-locking"
  # }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
