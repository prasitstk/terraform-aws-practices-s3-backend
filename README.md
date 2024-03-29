# terraform-aws-template

A template repository for Terraform project for AWS infrastructure.

## Architecture (optional)

<TODO: Add architecture diagram and describe it.>

---

## Prerequisites

<TODO: List all of the prerequisite architectural components and tools.>

---

## Tasks

<TODO: Describe each steps starting from initiating the Terraform project until to creating all of the resources.>

```sh
pwgen 20 1 -A

# backend "s3" is still commented.
# "aws_s3_bucket" "main_bucket" is still commented.

terrform init
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan

# Uncomment backend "s3".

terraform init -backend-config=backend.tfvars

# Uncomment "aws_s3_bucket" "main_bucket".

terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan

# Comment backend "s3".

terraform init -migrate-state
terraform plan -out /tmp/tfplan
terraform destroy
```

---

## Verification

<TODO: Describe how to verify the created stack.>

---

## Clean up

<TODO: Describe how to delete all stack resources after finishing this tutorial.>

---

## References (optional)

<TODO: List all references that you use to develop this Terraform project.>

---
