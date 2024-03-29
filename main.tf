########################
# Secure state storage #
########################

resource "aws_s3_bucket" "backend_bucket" {
  bucket = "terraform-backend-<random-string>"

  # After migrating the remote state file back to the local one, the remote state file still exists on the backend bucket.
  # So, with `force_destroy = true`, we can run `terraform destroy` to destroy the backend bucket even the remote state file still exists.
  force_destroy = true

  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_s3_bucket_versioning" "backend_bucket_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backend_bucket_lifecycle" {
  bucket = aws_s3_bucket.backend_bucket.id

  rule {
    id = "noncurrent-version-expiration-rule"

    noncurrent_version_expiration {
      # NOTE: The number of days an object is noncurrent before Amazon S3 can perform the associated action.
      noncurrent_days = 7

      # NOTE: The number of noncurrent versions Amazon S3 will retain.
      # newer_noncurrent_versions = 10
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_bucket_sse" {
  bucket = aws_s3_bucket.backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # NOTE: Using server-side encryption with Amazon S3-managed encryption keys (SSE-S3)
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backend_bucket_public_access_block" {
  bucket = aws_s3_bucket.backend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#######################
# State locking table #
#######################

resource "aws_dynamodb_table" "backend_state_lock_tbl" {
  name = "terraform-backend-state-lock-<random-string>"

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S" # NOTE: String type
  }

  tags = {
    "Name" = "DynamoDB Terraform State Lock Table"
  }
}

##################################
# Resources to verify the result #
##################################

# resource "aws_s3_bucket" "main_bucket" {
#   bucket_prefix = "main-"
#   force_destroy = true
# }