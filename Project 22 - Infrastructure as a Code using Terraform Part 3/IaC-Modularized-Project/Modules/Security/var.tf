variable "vpc_id" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "hosted_zone" {
  type = string
}
variable "tooling_record" {
  type = string
}
variable "wordpress_record" {
  type = string
}
variable "tags" {
  type = map(any)
}
variable "tag_prefix" {
  type = string
}
variable "ext-alb_dns_name" {
  type = string
}
variable "ext-alb_zone_id" {
  type = string
}
