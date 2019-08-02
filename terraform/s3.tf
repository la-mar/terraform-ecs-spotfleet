resource "aws_s3_bucket" "ops" {
  bucket = "${local.full_service_name}"
  acl    = "private"
  tags = local.tags

  lifecycle_rule {
    id      = "ia180"
    enabled = true
    tags = merge(local.tags, {lifecycle = "ia180"})

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }

  }
}

