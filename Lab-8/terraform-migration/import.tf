# import.tf
# This file tells Terraform: "There is already an EC2 instance running in
# AWS — link it to the resource block in main.tf instead of creating a
# new one."

import {
  to = aws_instance.migrated_server   # The resource block in main.tf
  id = "i-0123456789abcdef0"          # Replace with your real EC2 instance ID
}
