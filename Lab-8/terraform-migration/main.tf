# main.tf
# This file will hold the Terraform configuration for the EC2 instance
# we are bringing under Terraform's management.

provider "aws" {
  region = "us-east-1" # Change to match the region your EC2 instance is in
}

# This resource block is intentionally EMPTY at first.
# When migrating an existing resource into Terraform, you do NOT write the
# full configuration upfront — you start with just the resource type and
# a name, then let Terraform fill in the real values for you (see README).


resource "aws_instance" "migrated_server" {
  # Left empty on purpose — values will be filled in after import,
  # using the real settings of the existing EC2 instance.
}
