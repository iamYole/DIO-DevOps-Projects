provider "aws" {
  region = lookup(local.region, "US_Office")
}
