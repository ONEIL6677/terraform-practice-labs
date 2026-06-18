# Terraform Drift Detection & Management Guide

A comprehensive, beginner-friendly guide to understanding, detecting, and fixing configuration drift in Terraform-managed infrastructure.

## What is Configuration Drift?

**Terraform drift** happens when your real-world cloud infrastructure loses sync with your Terraform configuration files. 

*   **Managed Drift:** A team member manually changes a setting directly in the cloud console (e.g., AWS, Azure, GCP) instead of updating the code.
*   **Unmanaged Drift:** External events, auto-scaling policies, or cloud provider updates modify your resources behind your back.

## Why Drift Matters

*   **Security Risks:** Manual changes can accidentally expose private resources to the public internet.
*   **Broken Deployments:** Future deployments may fail or unexpectedly delete critical resources due to an inaccurate state file.
*   **Loss of Truth:** Your infrastructure code ceases to be the reliable blueprint of your actual environment.

## How to Detect Drift

### 1. Manual Detection
The fastest way to check for drift is by running the standard planning command:
```bash
terraform plan
```
*Terraform will compare your local code against the real-world infrastructure and list any discrepancies.*

### 2. State Refresh
To update your local state file with the real-world status without making any changes to your infrastructure:
```bash
terraform refresh
```

### 3. Automated Detection
For production environments, do not rely on manual checks. You can automate drift detection using:
*   **CI/CD Pipelines:** Schedule a daily GitHub Action or GitLab CI job to run `terraform plan`.
*   **Dedicated Tools:** Use open-source utilities or platform-native features (like Terraform Cloud health checks) to continuously scan for anomalies.

## How to Fix Drift

When drift is detected, you have three ways to remediate it:

| Strategy | Action | Best Used For... |
| :--- | :--- | :--- |
| **Sync Code** | Modify your `.tf` files to match the manual cloud changes. | Valid manual changes that you want to keep permanently. |
| **Overwrite Cloud** | Run `terraform apply` to overwrite manual changes. | Unauthorized or accidental changes that violate your code blueprint. |
| **Import Resource** | Run `terraform import <resource_type>.<name> <id>` | Resources that were completely created by hand outside of Terraform. |

---

## Contributing
Contributions are welcome! Please open an issue or submit a pull request if you have ideas to improve this guide.
