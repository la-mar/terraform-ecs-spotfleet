#! Cloudflare sin't working.
#!  It fails to lookup the specified zone.

# Configure the Cloudflare provider
# provider "cloudflare" {
#   email = "${var.cloudflare_email}"
#   token = "${var.cloudflare_token}"
# }

# # Create a record
# resource "cloudflare_record" "foobar" {
#   domain = "${var.cloudflare_zone_id}"
#   name   = "${var.subdomain}"
#   value  = aws_alb.main.dns_name
#   type   = "CNAME"
# }