terraform {
  backend "s3" {
    bucket = "ytech-terraform-state"
    key    = "ytech/s3/terraform.tfstate"
    region = "us-east-1"
    //dynamodb_table = "terraform-locks"
    encrypt = true
  }
}


