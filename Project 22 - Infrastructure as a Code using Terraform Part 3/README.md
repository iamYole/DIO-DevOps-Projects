# Infrastructure as a Code (IaC) using Terraform in AWS Part 3

In this project, we will continue from the part 2 of the IaC series. In this part, we will be enhancing the existing project by introducing new concepts like remote state management (Backend), workspace, dynamic blocks, modules, etc. Let's begin by introducing the backend.

## Terraform Backend (S3 and DynamoDB)

Terraform uses state files to keep track of the resources it manages and their current state. A backend is a configuration setting that determines where and how Terraform state data is stored and accessed. By default, terraform stores the state of each resource in a local file. However, this approach is not ideal when working on a team project were other team members are editing or creating new resources.

The local file terraform stores the state of each resource `terraform.tfstate`
![alt text](Images/Img_01.png)

Since the provider we are working with is AWS, the AWS S3 would be perfect for storing the backend/state file. Another useful option that is supported by S3 backend is State Locking – it is used to lock your state file for all operations that could write state. This prevents others from acquiring the lock and potentially corrupting your state. State Locking feature for S3 backend is optional and requires another AWS service – DynamoDB which we will be configuring as well.

Create a file called `backend.tf` and paste codes below.

> ```bash
> resource "aws_s3_bucket" "terraform_state" {
>  bucket = var.bucket
>  # Prevent accidental deletion
>  lifecycle {
>    prevent_destroy = true
>  }
> }
>
> # Enabling versioning to see the change history of the state file
> resource "aws_s3_bucket_versioning" "bucket_versioning" {
>  bucket = aws_s3_bucket.terraform_state.id
>
>  versioning_configuration {
>    status = "Enabled"
>  }
>  # Prevent accidental deletion
>  lifecycle {
>    prevent_destroy = true
>  }
> }
>
> # Enable server-side encryption by default
> resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
>  bucket = aws_s3_bucket.terraform_state.bucket
>
>  rule {
>    apply_server_side_encryption_by_default {
>      sse_algorithm = "AES256"
>    }
>  }
>  # Prevent accidental deletion
>  lifecycle {
>    prevent_destroy = true
>  }
> }
>
> resource "aws_dynamodb_table" "terraform_locks" {
>  name         = "terraform-locks"
>  billing_mode = "PAY_PER_REQUEST"
>  hash_key     = "LockID"
>  attribute {
>    name = "LockID"
>    type = "S"
>  }
>  # Prevent accidental deletion
>  lifecycle {
>    prevent_destroy = true
>  }
> }
> ```

Run `terraform plan` to inspect the changes.
![alt text](Images/Img_02.png)

The outcome of the `terraform plan` tells us 4 new resources would be created. The S3 bucket and its components as well as the dynamoDB table. These are required before we can configure Terraform to use S3 as backend. Now run `terraform apply` to implement the changes.

Confirm the S3 Bucket and DynamoDB table have been created.

S3 Bucket
![alt text](Images/Img_03.png)

DynamoDB Table
![alt text](Images/Img_04.png)

With the S3 bucket and DynamoDB table created, we can now configure the backend. Still in the `backend.tf` file, paste the code below

> ```bash
> terraform {
>  backend "s3" {
>    bucket         = "ytech-terraform-state"
>    key            = "ytech/s3/terraform.tfstate"
>    region         = "us-east-1"
>    dynamodb_table = "terraform-locks"
>    encrypt        = true
>  }
> }
> ```

Save the file and run `terraform init`. This will re initialize the project and then recognize the backend for remote state management. Terraform will also prompt you to copy the state of the existing resources to the backend.

![alt text](Images/Img_05.png)

The State file is now created in the S3 Bucket
![alt text](Images/Img_06.png)

Create a new file called `output.tf` with the code below

> ```bash
> output "s3_bucket_arn" {
>  value       = aws_s3_bucket.terraform_state.arn
>  description = "The ARN of the S3 bucket"
> }
> output "dynamodb_table_name" {
>  value       = aws_dynamodb_table.terraform_locks.name
>  description = "The name of the DynamoDB table"
> }
> ```

Save and then run `terraform apply`. Now, refresh the S3 page and confirm a new version of the file has been created while retaining the old version.
![alt text](Images/Img_07.png)

Few things to note from this section

- Ensure the S3 buckets and DynamoDB Table are not deleted by accident. This can be done by introducing the mete data `lifecycle`.
- When creating the `backend` resource, ensure the values are hard coded as it won't accept variables.
