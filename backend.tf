terraform {
  backend "s3" {
    bucket         = "terraform-github-gitlab-tf-state-backend"
    key            = "tf-infra/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-locking-table"
    encrypt        = true
  }
}