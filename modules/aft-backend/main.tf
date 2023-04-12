# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
data "aws_caller_identity" "current" {
  provider = aws.primary_region
}

# S3 Resources
resource "aws_s3_bucket" "primary-backend-bucket" {
  provider = aws.primary_region

  bucket = "aft-backend-${data.aws_caller_identity.current.account_id}-primary-region"

  tags = {
    "Name" = "aft-backend-${data.aws_caller_identity.current.account_id}-primary-region"
  }
}

resource "aws_s3_bucket_versioning" "primary-backend-bucket-versioning" {
  provider = aws.primary_region
  bucket   = aws_s3_bucket.primary-backend-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary-backend-bucket-encryption" {
  provider = aws.primary_region
  bucket   = aws_s3_bucket.primary-backend-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.encrypt-primary-region.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "primary-backend-bucket-acl" {
  provider = aws.primary_region
  bucket   = aws_s3_bucket.primary-backend-bucket.id
  acl      = "private"
}


resource "aws_s3_bucket_public_access_block" "primary-backend-bucket" {
  provider = aws.primary_region

  bucket = aws_s3_bucket.primary-backend-bucket.id

  block_public_acls   = true
  block_public_policy = true
}

# DynamoDB Resources
resource "aws_dynamodb_table" "lock-table" {
  provider = aws.primary_region

  name             = "aft-backend-${data.aws_caller_identity.current.account_id}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "LockID"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "Name" = "aft-backend-${data.aws_caller_identity.current.account_id}"
  }
}


# KMS Resources

resource "aws_kms_key" "encrypt-primary-region" {
  provider = aws.primary_region

  description             = "Terraform backend KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "aft-backend-${data.aws_caller_identity.current.account_id}-primary-region-kms-key"
  }
}

resource "aws_kms_alias" "encrypt-alias-primary-region" {
  provider = aws.primary_region

  name          = "alias/aft-backend-${data.aws_caller_identity.current.account_id}-kms-key"
  target_key_id = aws_kms_key.encrypt-primary-region.key_id
}
