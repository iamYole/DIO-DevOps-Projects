variable "keypair" {
  type = string
}
variable "account_id" {
  type = string
}

variable "bucket" {
  type = string
}
variable "your_ip" {
  type = string
}
variable "db_name" {
  type      = string
  sensitive = true
}
variable "master-username" {
  type      = string
  sensitive = true
}
variable "master-password" {
  type      = string
  sensitive = true
}
variable "tooling_record" {
  type = string
}
variable "wordpress_record" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "hosted_zone" {
  type = string
}



