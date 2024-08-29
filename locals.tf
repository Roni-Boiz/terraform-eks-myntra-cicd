locals {
  region             = "ap-south-1"
  availability_zones = ["ap-south-1a", "ap-south-1b"]

  bucket_name         = "terraform-github-gitlab-action-tf-state-backend"
  dynamodb_table_name = "terraform-state-locking-table"
}