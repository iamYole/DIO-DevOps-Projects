variable "enable_dns_support" {
  type = bool
}
variable "enable_dns_hostnames" {
  type = bool
}
variable "preferred_number_of_public_subnets" {
  type = number
}
variable "preferred_number_of_private_subnets" {
  type = number
}
variable "vpc_cidr" {
  type = string
}
variable "tags" {
  type = map(any)
}
variable "tag_prefix" {
  type = string
}
variable "tooling_record" {
  type = string
}
variable "ext-alb-sg_id" {
  type = string
}
variable "int-alb-sg_id" {
  type = string
}
variable "certificate_arn" {
  type = string
}


