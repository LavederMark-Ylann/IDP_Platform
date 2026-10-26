# Base syntax

```hcl
provider "official_provider_name" {
  arg = "value"
}

resource "official_resource_name" "personal_resource_name" {
  # args depends on the resource type
}
```

# Variables

Local variable

```hcl
locals {
  location = "Japan East"
}

# Reference : local.location
```

Input variable

```hcl
variable "location" {
  type    = string
  default = "Japan East"
}

# Reference : var.location
```

# Outputs

Used to expose values. Make them available after `terraform apply` to a another module. `terraform output` outputs the values.
Usually used with values produced by the configuration: resource IDs, IP addresses, endpoints...

```hcl
output "subnet_id" {
  value = azurerm_subnet.app.id
}
```

# Resource

Reprensent a part of infra that *Terraform* manages through plan (R) → apply (CUD).

For example, you can ask for a t3.micro EC2 on AWS, with 
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance  

```hcl
resource "aws_instance" "example" {
  ami           = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```

# Datasource

Just like a resource but read-only, so its lifecycle is **NOT** managed by Terraform. 

Recurring real-life use-cases:

- Shared infrastructure
  - A different Terraform manages the resource
  - A different team manages the resource
    - DB admin team owns all DB → Reference the DB as Datasource, as you're not authorized any modification on it
- Get info to avoid hard-coding variables present in the cloud provider
  - Subscription ID
  - Tenant ID
  - VM image
  - ...


```hcl
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}
```

# Multiple resource instances
Possible to have a foreach to avoid code repetition.
```hcl
resource "aws_instance" "front" {
  count = 3
}
```
For more customization, can use a variable that will have all the k/v
```hcl
variable "instances" {
  type = map(string)

  default = {
    ami1 = "ami-0123456789abcdef0"
    ami2 = "ami-1234567890abcdef0"
    ami3 = "ami-2345678901abcdef0"
  }
}
resource "aws_instance" "server" {
  for_each = var.instances
  ami = each.value
  instance_type = "t3.micro"
  tags = {
    Name = each.key
  }
}
```

# Module

Logical group of resources to avoid code repetition and standardize infrastructure across env, teams...

```hcl
module "network" {
  source = "./modules/network"

  location = var.location
}
```

# Expressions

Used to do interpolation, maths, conditions...

https://developer.hashicorp.com/terraform/language/expressions

# IMPORTANT
The tfstate generated may contains sensitive data (secrets) so it **SHOULD NEVER** be pushed on Git.

Also, if a team is working on it, it is possible to store it remotely
- s3
- consul
- backend supported by Terraform
- ...

How to do it: https://developer.hashicorp.com/terraform/language/state/remote


# CLI

## init
```
terraform init
```
Set up a Terraform project for the first time or after big changes (adding a provider, changing modules).

Download required providers and modules and initialize the configured backend if present

## fmt
```
terraform fmt
```
Format the code

## validate
```
terraform validate
```
Linter

## plan
```
terraform plan
```
Compare what's written and what's existing and shows the changes planned.

```
+ Create
~ Update
- Delete
-/+ Delete and recreate
+/- Create a replacement and delete old resource
```

## apply
```
terraform apply
```
Execute the changes planned

## destroy

```
terraform destroy
```
Plans and removes resources

# Dependencies

## Implicit dependency
If you want to create a Subnet, you'll be needing a VPC beforehand.

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

By referencing the block `aws_vpc.main.id`, `aws_subnet` indicates that it needs `aws_vpc` to exist and have values before being created.

## Explicit dependency

Sometimes, you have dependencies between resources without needing to have a reference between them.

```hcl
resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_instance" "app" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"

  depends_on = [
    aws_iam_role_policy_attachment.app
  ]
}
```

You'll be needing the IAM to be existing before creating the EC2. Therefore, by adding `depends_on`, you explicitly indicate to Terraform that it needs to create the IAM before the EC2.

# Lifecycle

Terraform's lifecycle block tells how Terraform creates, updates, replaces and destroys resources.

## create_before_destroy
Creates the replacement resource before destroying the old one. Reduce downtime.
```hcl
lifecycle {
  create_before_destroy = true
}
```

## prevent_destroy
Rejects plans that would destroy the resource while this rule remains in the configuration. Useful for critical databases.
```hcl
lifecycle {
  prevent_destroy = true
}
```

## ignore_changes
Ignores changes to specified attributes when planning updates. Useful when another system manages those attributes.
```hcl
lifecycle {
  ignore_changes = [tags]
}
```
Will ignores differences in tags for update planning

## replace_triggered_by
Replaces a resource when a referenced resource or resource attribute changes
```hcl
lifecycle {
  replace_triggered_by = [
    aws_launch_template.app
  ]
}
```
Useful when a change to one resource should trigger replacement of another. References must be supported resource or attribute references.

## precondition
Checks an assumption before proceeding. If false, throw an error.
```hcl
lifecycle {
  precondition {
    condition     = var.environment == "production"
    error_message = "This resource requires production."
  }
}
```
Requirements before provisioning

## postcondition
Creates the replacement resource before destroying the old one. Reduce downtime.
```hcl
lifecycle {
  postcondition {
    condition     = self.id != ""
    error_message = "The resource must have an ID."
  }
}
```
Verify that the resource satisfies the condition
