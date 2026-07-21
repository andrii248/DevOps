terraform {
  backend "s3" {
    bucket         = "andy-lesson-5-tfstate"
    key            = "lesson-db-module/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}