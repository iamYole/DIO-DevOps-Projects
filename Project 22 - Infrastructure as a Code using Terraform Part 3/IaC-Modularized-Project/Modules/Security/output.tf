output "datalayer-sg_id" {
  value = aws_security_group.datalayer-sg.id
}
output "tooling_record" {
  value = aws_route53_record.tooling
}
output "int-alb-sg_id" {
  value = aws_security_group.int-alb-sg.id
}
output "ext-alb-sg_id" {
  value = aws_security_group.ext-alb-sg.id
}
output "certificate_arn" {
  value = aws_acm_certificate_validation.iamyole.certificate_arn
}
output "bastion_sg-id" {
  value = aws_security_group.bastion_sg.id
}
output "nginx_sg-id" {
  value = aws_security_group.nginx-sg.id
}
output "webserver_sg-id" {
  value = aws_security_group.webserver-sg.id
}
