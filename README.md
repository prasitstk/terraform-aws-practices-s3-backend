# Store Terraform state remotely on Amazon S3

The default Terraform state for a project is stored in a local file named `terraform.tfstate`. However, using this local state becomes impractical when collaborating across multiple machines or users. To address this, the state must be stored remotely. Terraform offers various built-in remote backend storage options, such as Amazon S3 bucket and DynamoDB table (for locking mechanism), which I'll demonstrate here.

## Prerequisites

- An AWS account with an IAM User that has required permissions to create/update/delete resources by Terraform CLI.
- Access keys of that IAM User.
- Terraform (version >= 0.13)

---

## Tasks

Create `terraform.tfvars` to define variables for Terraform as follows:

```hcl
aws_region     = "<aws-account-region>"
aws_access_key = "<aws-account-access-key>"
aws_secret_key = "<aws-account-secret-key>"
```

Create `backend.tfvars` to define partial configuration of the remote backend by the same AWS access keys as follows:

```hcl
access_key = "<aws-account-access-key>"
secret_key = "<aws-account-secret-key>"
```

> NOTE: Notice that I define both partial configurations externally from the remote backend instead of using the variables defined in `terraform.tfvars`. This is because the `backend` block in Terraform code doesn't permit the use of variables (`var.aws_access_key` and `var.aws_secret_key`) inside it. However, we can utilize the partial configuration with `terraform init -backend-config=/path/to/backend.tfvars` instead.

Run `pwgen` to generate random string for S3 bucket for S3 bucket to make its name globally unique as follows:

```sh
# For example, the below command will generate one 20-character random string without capital letters.
pwgen 20 1 -A
```

Then replace the randomly-generated string generated from the pwgen command above with <random-string> placeholders at the ends of S3 bucket names in main.tf and providers.tf.

Because we need Terraform to create the S3 bucket where you want to store your Terraform state. This cannot be done in one step. To make this work, you have to perform the two-step process as follows:

1. Write Terraform code to create the S3 bucket and DynamoDB table, and deploy that code with a local state file (`local` backend).

2. Go back to the Terraform code, add a `s3` remote backend configuration to it to use the newly created S3 bucket and DynamoDB table, and run `terraform init` again to move your local state file into S3 bucket.

Later if you would like to destroy the entire stack including both S3 bucket and DynamoDB table for remote backend, you need to do this two-step process in reverse as follows:

1. Go to the Terraform code, remove the backend configuration, and run `terraform init -migrate-state` to copy the Terraform state back to your local disk.

2. Run `terraform destroy` to delete the S3 bucket and DynamoDB table along with other resources from the entire stack.

Now let's start with creating the remote backend resources on AWS and save the state locally. On `providers.tf`, make sure that `backend "s3"` block is still commented and run the following commands to initialize the project, plan, and apply the backend resource creation into the local state file by:

```sh
# Make sure `backend "s3"` block on `providers.tf` is still commented.
terraform init
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan
```

You should see that `terraform.tfstate` file is created with the state information responding to the newly created backend resources. Then we go to the next step to move that local state file into S3 bucket by uncommenting the `backend "s3"` block on `providers.tf` file and run the following command:

```sh
# Uncomment backend "s3" block on `providers.tf`. Then:
terraform init -backend-config=backend.tfvars
```

Notice that the content in the `terraform.tfstate` will be copied into the `test/remote_terraform.tfstate` and uploaded into the `terraform-backend-<random-string>` S3 bucket. However, the local `terraform.tfstate` still exists but it will be empty and not be used anymore.

To verify that the remote state file is working, attempt to create a new working resource in the stack. Navigate to `main.tf` and uncomment `"aws_s3_bucket" "main_bucket"` block. Then run the following commands:

```sh
# Uncomment "aws_s3_bucket" "main_bucket" on `main.tf`.
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan
```

Expected outcomes:

- Successful execution of `terraform apply`.
- An empty `terraform.tfstate` file.
- A new S3 bucket named "main-<random-string-characters-from-s3>".

---

## Clean up

To clean up the entire stack including all of the remote backend and working resources, as I mentioned before, we need to comment out the `backend "s3"` block on `providers.tf` file and then copy the Terraform state information back to your local disk by:

```sh
# Comment backend "s3" block on `providers.tf`.
terraform init -migrate-state
```

Now you should see the state information is back to `terraform.tfstate` file. Then run the following command to delete all resources:

```sh
terraform destroy
```

If `-auto-approve` is set, then the destroy confirmation will not be shown:

```sh
terraform destroy -auto-approve
```

---

## References (optional)

- [Managing S3 bucket for Terraform backend in the same configuration](https://dev.to/shihanng/managing-s3-bucket-for-terraform-backend-in-the-same-configuration-2c6c)
- [AWS Terraform S3 and dynamoDB backend](https://angelo-malatacca83.medium.com/aws-terraform-s3-and-dynamodb-backend-3b28431a76c1)
- [How to manage Terraform state](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa#01db)
- [Terraform Remote States in S3](https://medium.com/dnx-labs/terraform-remote-states-in-s3-d74edd24a2c4)
- [S3 Terraform Backend](https://earthly.dev/blog/terraform-state-bucket/)
- [Terraform S3 Backend Best Practices](https://technology.doximity.com/articles/terraform-s3-backend-best-practices)
- [DNXLabs/terraform-aws-backend](https://github.com/DNXLabs/terraform-aws-backend)
- [Terraform S3 Backend Best Practices](https://technology.doximity.com/articles/terraform-s3-backend-best-practices)
- [How to Manage Terraform S3 Backend – Best Practices](https://spacelift.io/blog/terraform-s3-backend)
- [How to Store Terraform State on S3](https://medium.com/all-things-devops/how-to-store-terraform-state-on-s3-be9cd0070590)
- [How to set Terraform backend configuration dynamically](https://brendanthompson.com/posts/2021/10/dynamic-terraform-backend-configuration)
- [What is terraform Backend & How used it](https://medium.com/@surangajayalath299/what-is-terraform-backend-how-used-it-ea5b36f08396)
- [Chicken or the Egg? Terraform’s Remote Backend](https://www.monterail.com/blog/chicken-or-egg-terraforms-remote-backend/)

---
