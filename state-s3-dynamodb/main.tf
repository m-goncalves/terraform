provider "aws" {
    region = "sa-east-1"
}

resource "aws_s3_bucket" "s3_bucket" {
    # The bucket must be created before the creation of the backend.
    # The name of the s3-bucket must be unique.
    bucket = "unique-tf-state-bucket"
    lifecycle {
      prevent_destroy = true
    }

    # Enable versioning so that the full revision history 
    # of the file can be seen.
    versioning {
      enabled = true
    }

    # Enables server-side encryption by default.
    server_side_encryption_configuration {
      rule {
          apply_server_side_encryption_by_default {
              sse_algorithm = "AES256"
          }
       }
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
    name            = "terraform_locks"
    billing_mode    = "PAY_PER_REQUEST"
    hash_key        = "LockID"

    attribute {
      name          = "LockID"
      type          = "S"
    }
}

# Configure a terraform backend without which the
# state would still be saved locally.
# At this point the bucket must already have been created.
# Variables are not allowed here.
terraform {
  backend "s3" {
      bucket            = "unique-tf-state-bucket"
      # The file path where the state file will be written.
      key               = "global/s3/terraform.tfstate"
      region            = "sa-east-1"
      dynamodb_table    = "terraform_locks"
      # Ensures that the terraform state will be encrypted on disk. 
      encrypt           = true
  }
}

# To delete the DynamoDB and the S3 Bucket the backend must be deleted first.
# As for the creation of S3 and DB, their deletion must be a two step process.
output "s3_bucket_arn" {
    value           = "aws_s3_bucket.s3_bucket.arn"
    description     = "The ARN of the s3 bucket."
}

output "dynamodb_table_name" {
    value           = "aws_dynamodb_table.terraform_locks.name"
    description     = "The name of the DynamoDB table."
}