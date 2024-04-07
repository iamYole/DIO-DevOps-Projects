variable "datalayer-sg_id" {
  type = string
}
variable "private_subnets" {
  type = list(any)
}
variable "tags" {
  type = map(any)
}
variable "tag_prefix" {
  type = string
}
