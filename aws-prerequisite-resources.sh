#!/bin/bash

# Variables
BUCKET_NAME="terraform-github-gitlab-tf-state-backend"
DYNAMODB_TABLE_NAME="terraform-state-locking-table"
REGION="ap-south-1"

# Check if S3 bucket exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" &>/dev/null; then
  echo "S3 bucket $BUCKET_NAME already exists."
else
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
  aws s3api put-bucket-policy --bucket terraform-github-gitlab-tf-state-backend --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:ListBucketVersions"
        ],
        "Resource": [
          "arn:aws:s3:::terraform-github-gitlab-tf-state-backend",
          "arn:aws:s3:::terraform-github-gitlab-tf-state-backend/*"
        ]
      }
    ]
  }'
  aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
  aws s3api head-bucket --bucket "$BUCKET_NAME"
fi

# Check if DynamoDB table exists
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME" --region "$REGION" &>/dev/null; then
  echo "DynamoDB table $DYNAMODB_TABLE_NAME already exists."
else
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME" --region "$REGION"
fi
