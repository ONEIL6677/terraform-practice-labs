# Using Terraform Modules from the Registry

This project demonstrates how to source, configure, and deploy infrastructure using pre-built modules from the official [Terraform Registry](https://terraform.io). 

Using registry modules allows us to leverage battle-tested, community-maintained infrastructure patterns instead of writing complex cloud resources from scratch.

---

## Prerequisites

Before running this configuration, ensure you have:
*   [Terraform CLI](https://hashicorp.com) installed (v1.5.0+)
*   An active AWS account with configured CLI credentials (`aws configure`)

---

## File Structure

This repository follows standard Terraform naming conventions:
*   `main.tf` - Calls the registry module and manages core provider settings.
*   `variables.tf` - Declares the input variables for customization.
*   `terraform.tfvars` - Supplies the runtime values for the variables.
*   `outputs.tf` - Captures and exposes the resources created by the module.

---

## Code Example: Deploying an AWS VPC

Below is an example of how to pull the official AWS VPC module into your `main.tf` file.

```hcl
# main.tf

# 1. Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# 2. Call the Registry Module
module "vpc" {
  # The exact path from registry.terraform.io
  source  = "terraform-aws-modules/vpc/aws"
  
  # ALWAYS lock your module to a specific version
  version = "5.13.0"

  # Module Input Variables
  name = "\${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = ["\({var.aws_region}a", "\){var.aws_region}b"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

---

## How to Deploy This Infrastructure

Follow these exact terminal commands to initialize and deploy the module:

### 1. Initialize the Workspace
This command scans your `main.tf`, identifies the registry module source, and automatically downloads the module code into a hidden `.terraform/modules` directory.
```bash
terraform init
```

### 2. Preview the Changes
Generate an execution plan to see exactly what resources the registry module will create on your cloud provider.
```bash
terraform plan
```

### 3. Apply the Configuration
Deploy the infrastructure. Review the final plan and type `yes` to confirm.
```bash
terraform apply
```

---

## Key Best Practices for Registry Modules

*   **Pin Your Versions:** Never omit the `version` argument. Without it, Terraform will download the newest version during initialization, which might introduce breaking changes to your environment.
*   **Inspect the Inputs/Outputs:** Every registry page has an **Inputs** and **Outputs** tab. Check these tabs to see what configuration settings are required and what data you can pass to other resources.
*   **Review Module Dependencies:** Some modules automatically create auxiliary resources (like IAM roles or security groups). Always run `terraform plan` to understand exactly what is being built.
