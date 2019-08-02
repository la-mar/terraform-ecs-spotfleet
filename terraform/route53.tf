# %% uncomment to create hosted zone, if needed
# resource "aws_route53_zone" "tld" {
#     name = "${var.tld}"

#     tags = "${local.tags}"
# }

# Load the public hosted zone for the primary top level domain
data "aws_route53_zone" "tld" {
  name = var.tld
}

# Zone record mapping ALB to public DNS name
resource "aws_route53_record" "env" {
  zone_id = data.aws_route53_zone.tld.zone_id
  name    = "${var.subdomain}.${var.tld}"
  type    = "CNAME"
  ttl     = 3000

  records = [
    aws_alb.main.dns_name,
  ]
}

# Load private hosted zone for RDS dns
data "aws_route53_zone" "db" {
  name         = "db."
  private_zone = true
}

# Zone record mapping RDS to private DNS name
resource "aws_route53_record" "db" {
  zone_id = data.aws_route53_zone.db.zone_id
  name    = "ops.${var.environment}.${data.aws_route53_zone.db.name}"
  type    = "CNAME"
  ttl     = 3000

  records = [
    aws_db_instance.db.address,
  ]
}

