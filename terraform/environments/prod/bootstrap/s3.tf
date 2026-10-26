// Can't create S3 with Terraform with Free Tier on AWS (?) : Via UI

/* data "aws_s3_bucket" "remote_state" {
  bucket = "idp-platform-project-remote-tf-state"
}

resource "aws_s3_bucket_acl" "remote_bucket_acl" {
  bucket = data.aws_s3_bucket.remote_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "remote_bucket_versioning" {
  bucket = data.aws_s3_bucket.remote_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "remote_bucket_access" {
  bucket = data.aws_s3_bucket.remote_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = data.aws_s3_bucket.remote_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
} */