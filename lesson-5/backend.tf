terraform {
  backend "s3" {
    bucket         = "andy-lesson-5-tfstate"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}