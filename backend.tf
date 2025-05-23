terraform {
  backend "s3" {
    bucket  = "orion-task-terraform-state"
    key     = "dev/terraform-dev-state/dev.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}