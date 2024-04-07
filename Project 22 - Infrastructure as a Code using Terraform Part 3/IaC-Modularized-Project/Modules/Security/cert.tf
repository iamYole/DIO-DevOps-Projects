# The entire section creates a certificate, public zone, and validates the certificate using DNS method.




# Create the certificate using a wildcard for all the domains created in oyindamola.gq
resource "aws_acm_certificate" "yole" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

/* #creating the hosted zone
resource "aws_route53_zone" "iamyole" {
  name = "iamyole"

  tags = merge(
    var.tags, {
      Name = "${var.tag_prefix}_Domain"
    }
  )
} */

# calling the hosted zone
data "aws_route53_zone" "iamyole" {
  # depends_on   = [aws_route53_zone.iamyole]
  name         = var.hosted_zone
  private_zone = false
}


# selecting validation method
resource "aws_route53_record" "iamyole" {
  for_each = {
    for dvo in aws_acm_certificate.yole.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.iamyole.zone_id
}

# validate the certificate through DNS method
resource "aws_acm_certificate_validation" "iamyole" {
  certificate_arn         = aws_acm_certificate.yole.arn
  validation_record_fqdns = [for record in aws_route53_record.iamyole : record.fqdn]
}

# create records for tooling
resource "aws_route53_record" "tooling" {
  zone_id = data.aws_route53_zone.iamyole.zone_id
  name    = var.tooling_record
  type    = "A"

  alias {
    name                   = var.ext-alb_dns_name //aws_lb.ext-alb.dns_name
    zone_id                = var.ext-alb_zone_id  //aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}


# create records for wordpress
resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.iamyole.zone_id
  name    = var.wordpress_record
  type    = "A"

  alias {
    name                   = var.ext-alb_dns_name //aws_lb.ext-alb.dns_name
    zone_id                = var.ext-alb_zone_id  //aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}

