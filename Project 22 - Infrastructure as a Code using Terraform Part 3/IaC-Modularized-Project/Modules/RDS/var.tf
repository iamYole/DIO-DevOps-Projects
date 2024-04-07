variable "db_name" {
  type = string
}
variable "master-username" {
  type = string
}
variable "master-password" {
  type      = string
  sensitive = true
}
variable "private_subnets" {
  type = list(any)
}
variable "public_subnets" {
  type = list(any)
}
variable "datalayer-sg_id" {
  type = string
}
variable "tags" {
  type = map(any)
}
variable "tag_prefix" {
  type = string
}
