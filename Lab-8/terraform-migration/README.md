# Terraform Migration — Bringing Existing AWS Resources Under Terraform

A simple guide to migrating **any** AWS resource that was created manually
(or by another tool) into Terraform management with a worked **EC2
instance** example at the end.

---

## What is Terraform Migration?

"Terraform migration" means taking infrastructure that **already exists**
in the cloud created manually in the AWS Console, with a script, or with
another tool and making Terraform **aware of it**, so Terraform can
manage it going forward.

This is different from a normal `terraform apply`, where Terraform
**creates new resources**. Here, the resource already exists we just
need to tell Terraform: *"this is mine now, track it."*

### Why Would You Need This?

- You started a project by manually clicking around the AWS Console, and now want to manage it properly with code
- You inherited infrastructure from someone else with no Terraform code behind it
- You're standardizing your team's infrastructure and slowly moving everything into Terraform

### Why Not Just Delete and Recreate It With Terraform?

Because the resource might be running a live application, holding data, or
serving real traffic. Migration lets you keep the resource **exactly as
it is** — same IP, same data, same uptime — while gaining the benefits of
Terraform (version control, repeatability, drift detection) going forward.

---

## The General Process (Works for ANY Resource)

This same 7-step process applies whether you're migrating an EC2 instance,
an S3 bucket, a security group, an IAM role, an RDS database, or anything
else Terraform supports. Only two things change per resource: the
**resource type** (e.g. `aws_instance` vs `aws_s3_bucket`) and the
**identifier** used to find it in AWS (e.g. instance ID vs bucket name).

```
┌──────────────────────────┐        ┌───────────────────────────┐
│   Existing AWS resource   │        │   main.tf (resource block) │
│   (created manually)      │  ───►  │   import.tf (import block) │
└──────────────────────────┘        └───────────────────────────┘
                                              │
                                              ▼
                                    terraform plan / apply
                                              │
                                              ▼
                                  Terraform now manages this
                                  resource going forward
```

### Step 1: Find the Resource's Identifier

Every AWS resource has some unique identifier Terraform needs to find it.
This varies by resource type:

| Resource Type | Terraform Resource | Identifier Needed |
|---|---|---|
| EC2 Instance | `aws_instance` | Instance ID (e.g. `i-0123456789abcdef0`) |
| S3 Bucket | `aws_s3_bucket` | Bucket name |
| Security Group | `aws_security_group` | Security Group ID (e.g. `sg-0abc123`) |
| IAM Role | `aws_iam_role` | Role name |
| RDS Database | `aws_db_instance` | DB instance identifier |
| VPC | `aws_vpc` | VPC ID (e.g. `vpc-0abc123`) |

You can find most of these in the AWS Console, or via the AWS CLI, e.g.:

```bash
aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId"
aws s3api list-buckets --query "Buckets[].Name"
```

### Step 2: Add an Empty Resource Block

In your `.tf` file, add an empty resource block as a placeholder. Pick the
correct resource type for what you're migrating:

```hcl
resource "aws_instance" "my_resource" {
  # Left empty for now
}
```

The label (`my_resource`) is just an internal name you choose it **must**
match the `import` block in the next step.

### Step 3: Add an Import Block

Create an `import` block or an import.tf file linking your placeholder resource to the real
AWS resource:

```hcl
import {
  to = aws_instance.my_resource     # The resource block above
  id = "i-0123456789abcdef0"        # The real AWS identifier
}
```

### Step 4: Generate the Real Configuration

Run a plan with the `-generate-config-out` flag. Terraform will read the
**actual settings** of the resource from AWS and write them into a new
file for you so you don't have to manually guess every setting:

```bash
terraform init
terraform plan -generate-config-out=generated.tf
```

### Step 5: Replace the Empty Block With the Generated One

Open `generated.tf`, copy its contents into your real `main.tf` file (replacing
the empty placeholder block), then delete `generated.tf`.

### Step 6: Plan and Apply

```bash
terraform plan
```

If everything matches, the plan should show **no changes** (or only minor
ones). This confirms Terraform's view now matches reality.

```bash
terraform apply
```

This finalizes the import — Terraform now tracks the resource in its state
file, exactly as if it had created it.

### Step 7: Remove the Import Block

Once applied successfully, delete the `import` block `import.tf` file it's only needed once, during the migration itself.

### Verifying Any Migration Worked

```bash
terraform state list                        # Confirms the resource is tracked
terraform state show aws_instance.my_resource  # Shows everything Terraform knows about it
```

---

## Worked Example — Migrating an EC2 Instance

Below is the general process above applied to one concrete case: an EC2
instance that was launched manually in the AWS Console.

### Project Files

```
terraform-ec2-import/
├── main.tf        # Provider config + an empty resource block to receive the import
├── import.tf      # The import block linking Terraform to the real EC2 instance
└── README.md      # This file
```

### Step 1 — Find the EC2 Instance ID

```bash
aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId"
```

Example result: `i-0123456789abcdef0`

### Step 2 — Empty Resource Block (`main.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "migrated_server" {
  # Left empty for now
}
```

### Step 3 — Import Block (`import.tf`)

```hcl
import {
  to = aws_instance.migrated_server
  id = "i-0123456789abcdef0"   # Replace with YOUR instance ID
}
```

### Step 4 — Generate Configuration

```bash
terraform init
terraform plan -generate-config-out=generated.tf
```

### Step 5 — Replace and Clean Up

Copy the generated `aws_instance.migrated_server` block from
`generated.tf` into `main.tf`, replacing the empty one. Delete
`generated.tf`.

### Step 6 — Apply

```bash
terraform plan    # Should show no changes, or only minor ones
terraform apply
```

### Step 7 — Remove the Import Block

Delete `import.tf` — the migration is complete.

### Verify

```bash
terraform state list
# aws_instance.migrated_server

terraform state show aws_instance.migrated_server
```

---

## Important Notes

- **Nothing is destroyed or recreated** during migration — the resource keeps running the entire time
- Always run `terraform plan` before `apply` to confirm no unexpected changes will be made
- The same process works for almost any AWS resource — just change the resource type and identifier
- Keep a backup of your Terraform state file before doing imports on critical infrastructure

---

## Author

**ONEIL KIMBI**
Version: v1.0.0
