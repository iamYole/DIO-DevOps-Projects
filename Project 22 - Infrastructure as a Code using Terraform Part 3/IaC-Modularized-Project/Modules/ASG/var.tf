variable "keypair" {
  type = string
}
variable "private_subnets" {
  type = list(any)
}
variable "public_subnets" {
  type = list(any)
}
variable "tags" {
  type = map(any)
}
variable "tag_prefix" {
  type = string
}
variable "bastion_sg-id" {
  type = string
}
variable "nginx_sg-id" {
  type = string
}
variable "webserver_sg-id" {
  type = string
}
variable "image" {
  type = map(map(any))

  default = {
    "US_Office" = {
      "RHEL_9"           = "ami-0fe630eb857a6ec83"
      "Ubuntu_Server_22" = "ami-080e1f13689e07408"
    },
    "London_Office" = {
      "RHEL_9"           = "ami-035cecbff25e0d91e"
      "Ubuntu_Server_22" = "ami-0b9932f4918a00c4f"
    }
  }
}
variable "instance_type" {
  type = map(any)

  default = {
    "small"  = "t2.micro"
    "medium" = "t3.medium"
    "large"  = "r5.large"
  }
}
variable "nginx_tg-arn" {
  type = string
}
variable "wordpress_tg-arn" {
  type = string
}
variable "tooling_tg-arn" {
  type = string
}
