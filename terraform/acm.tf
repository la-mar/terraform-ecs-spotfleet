data "aws_acm_certificate" "main" {
  domain   = "*.${var.tld}"
  statuses = ["ISSUED"]
}