# Making the VPC ID available to other Modules
output "vpc_id" {
  value = aws_vpc.dio-vpc.id
}
output "ext-alb_dns_name" {
  value = aws_lb.ext-alb.dns_name
}
output "ext-alb_id" {
  value = aws_lb.ext-alb.id
}
output "ext-alb_zone_id" {
  value = aws_lb.ext-alb.zone_id
}
output "alb_dns_name" {
  value = aws_lb.ext-alb.dns_name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.nginx-tgt.arn
}
output "public_subnets" {
  value = aws_subnet.public[*]
}
output "private_subnets" {
  value = aws_subnet.private[*]
}
output "nginx_tg-arn" {
  value = aws_lb_target_group.nginx-tgt.arn
}
output "wordpress_tg-arn" {
  value = aws_lb_target_group.wordpress-tgt.arn
}
output "tooling_tg-arn" {
  value = aws_lb_target_group.tooling-tgt.arn
}
