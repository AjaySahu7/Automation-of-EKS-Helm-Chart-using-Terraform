resource "aws_route53_zone" "bastion_domain" {
  name = var.bastion_domain_name

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "bastion-A-record" {
  name = var.hostname
  records = [var.private_ip]
  zone_id = "${aws_route53_zone.bastion_domain.id}"
  type = "A"
  ttl = "300"
}

resource "aws_route53_zone" "app-domains" {
 count = length(var.app_domain_name)
  name = element(var.app_domain_name,count.index)

  vpc {
    vpc_id = var.vpc_id
  }
}