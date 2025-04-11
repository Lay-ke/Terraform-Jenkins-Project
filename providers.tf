terraform {
    backend "s3" {
    bucket         = "mics3tfdemo1"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    # dynamodb_table = "terraform-state-lock"   // The name of your DynamoDB table for state locking
    acl            = "bucket-owner-full-control"
  }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}