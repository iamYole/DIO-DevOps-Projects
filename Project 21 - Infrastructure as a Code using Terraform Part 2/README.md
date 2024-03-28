# Infrastructure as a Code (IaC) using Terraform in AWS Part 2

In the first part of this project [Infrastructure as a Code (IaC) using Terraform in AWS](https://github.com/iamYole/DIO-Projects/blob/main/Project%2016%20-%20Infrastructure%20as%20a%20Code%20using%20Terraform/README.md), we were introduce to the basics of IaC with terraform and provisioned a VPC, Subnets, and and EC2 Instance. We will be building on that by creating the resources in the diagram below.

![alt text](Images/diagram.png)

Let's begin with a recap from the previous part. In the previous part, we created a VPC `dio-vpc` and two public subnets. We leveraged on the `data` block to create a data source of the availability zones in the region and selected the first 2. The code was also refactored to use the `variables.tf` to define the variables and the `terraform.tfvars` file to set the values.

Now, let's add 4 Private Subnets to the VPC.

## IaC - Networking

### Creating the Private Subnets

Before we continue, one of the the project requirement is creating tags for all resources, and we've been given a format/template on the minimum tag each resource should have.

> ```yaml
> Environment     = "production"
> Owner-Email     = "devopsAdmin@darey.io"
> Managed-By      = "Terraform"
> Billing-Account = "1234567890"
> ```

To comply with the above tag requirement, we can create a tag variable in the `variable.tf` file, and then for each object we create, we reference the tag. Let's start by re tagging the exiting objects (VPC, and Public Subnets).

- Add the following lines of code to the `variables.tf` file
  > ```bash
  > variable "tag_prefix" {
  >   default = "DIO"
  > }
  >
  > variable "tags" {
  >  default = {
  >    "Environment"     = "Production"
  >    "Owner-Email"     = "devopsadmin@darey.io"
  >    "Managed-By"      = "Terraform"
  >    "Billing-Account" = "1234567890"
  >  }
  > }
  > ```
- In the `main.tf` file, delete the current tags in the VPC and subnet, and then replace them with the codes below
  > ```bash
  > #VPC tag
  > tags = merge(
  >    var.tags, {
  >      Name = "dio-vpc"
  >    }
  >  )
  >
  > #Subnets Tag
  > tags = merge(
  >  var.tags,
  >  {
  >    Name = "pub_sub_${count.index + 1}"
  >  },
  > )
  > ```

With the modified code above, each resource will inherit details of the default tag, and the name of the resource will be appended to the tag.

Now, let's continue with the 4 private subnets.

- The first step is to create a variable in the `variables.tf` file
  > ```bash
  > variable "preferred_number_of_private_subnets" {
  >     default = null
  > }
  > ```
- In the `terraform.tfvars` file, let's set the number
  > `preferred_number_of_private_subnets = 4`
- Now, in the `main.tf` file, add the following lines of code
  > ```bash
  > # Create private subnets
  >  resource "aws_subnet" "private" {
  >  count                   = var.preferred_number_of_private_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_private_subnets
  >  vpc_id                  = aws_vpc.dio-vpc.id
  >  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index * 2 + 1) #Using odd numbers for the CIDR_BLOCK
  >  map_public_ip_on_launch = false
  >  availability_zone       = data.aws_availability_zones.available.names[count.index]
  >
  >  tags = merge(
  >    var.tags,
  >    {
  >      Name = "priv_sub_${count.index + 1}"
  >    },
  >  )
  > }
  >
  > ```
- Run `terraform validate` to ensure there are no syntax errors, and then `terraform plan` to see the execution plan.

        Note, in the previous step, I created the resources in the eu-west-2 region which has just 3 AZs. This would be a problem as we are attempting to create 4 subnets.
        To fix this, I've changed the region to us-east-1, which has 6 AZs.

        Another point to note. When we dynamically allocated the cidr_block to the public subnet, we used the code below
        cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 1). Since we were creating two public subnets, the cidr_block will start at one and increment by 1.

        That approach worked just fine. However, when implementing the cidr_block allocation for the private subnet, we need to create a logic where there won't be a conflict.

        To do that, we allocate even numbers to the public subnet using code below
        cidr_block = cidrsubnet(var.vpc_cidr, 4, (count.index + 1) * 2). This will generate
        (0 + 1) * 2 = 2
        (1 + 1) * 2 = 4

        and for the private subnet, we use the code below
        cidr_block = cidrsubnet(var.vpc_cidr, 4, ((count.index + 1) * 2) + 1)). This will generate
        ((0 + 1) * 2) + 1 = 3
        ((1 + 1) * 2) + 1 = 5

- Run `terraform apply --auto-approve` to create the resources.
- Log into the AWS Console to confirm the resources have been created and tagged accordingly.
  ![alt text](Images/Img_01.png)
  We can see the VPC has been created and tagged as expected

  ![alt text](Images/Img_02.png)

  We can also see the private and public subnets have been created, the CIDR_BLOCK had no conflict

Next, we will be creating an Internet Gateway, an Elastic IP and a NAT Gateway.

### Creating the Internet Gateway, NAT Gateway and Elastic IP

In a bid not to have one file containing a long line of codes, we can create new files to and group the items being created. That way, our code becomes was to read as well as manage. Let's create a new file for the IGW, NAT GW and EIP

Create a new file called `IG_NAT_EIP.tf` with the code below:

> ```bash
> # Create Internet Gateway
> resource "aws_internet_gateway" "ig" {
> vpc_id = aws_vpc.dio-vpc.id
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_IGW"
>    }
>  )
> }
>
> # Create Elastic IP
> resource "aws_eip" "nat_eip" {
>  depends_on = [aws_internet_gateway.ig]
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_NAT_EIP"
>    },
>  )
> }
>
> # Create NAT Gateway
> resource "aws_nat_gateway" "nat" {
>  allocation_id = aws_eip.nat_eip.id
>  subnet_id     = element(aws_subnet.public.*.id, 0)
>  depends_on    = [aws_internet_gateway.ig]
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_NAT"
>    },
>  )
> }
>
> ```

Run `terraform plan` to inspect the changes and then `terraform apply -auto-approve` to implement the changes.
![alt text](Images/Img_03.png)

The Internet Gateway, Elastic IP and NAT Gateway has now been created. Again, this can be verified from the AWS Console.

The EIP
![alt text](Images/Img_04.png)

The NAT GW with the EIP attached
![alt text](Images/Img_05.png)

The IGW
![alt text](Images/Img_06.png)

### Creating the Route Tables

Again, let's create new file called `route_tables.tf` with the code below:

> ```bash
> # create private route table
> resource "aws_route_table" "private-rtb" {
>  vpc_id = aws_vpc.dio-vpc.id
>
>  route {
>    cidr_block = "0.0.0.0/0"
>    gateway_id = aws_nat_gateway.nat.id
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_private-rtb"
>    }
>  )
> }
>
> # associate all private subnets to the private route table
> resource "aws_route_table_association" "private-subnets-assoc" {
>  count          = length(aws_subnet.private[*].id)
>  subnet_id      = element(aws_subnet.private[*].id, count.index)
>  route_table_id = aws_route_table.private-rtb.id
> }
>
> # create route table for the public subnets
> resource "aws_route_table" "public-rtb" {
>  vpc_id = aws_vpc.dio-vpc.id
>
>  route {
>    cidr_block = "0.0.0.0/0"
>    gateway_id = aws_internet_gateway.ig.id
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_public-rtb"
>    }
>  )
> }
>
> # associate all public subnets to the public route table
> resource "aws_route_table_association" "public-subnets-assoc" {
>   count          = length(aws_subnet.public[*].id)
>   subnet_id      = element(aws_subnet.public[*].id, count.index)
>   route_table_id = aws_route_table.public-rtb.id
> }
> ```

In the code above, we created the Public and Private `Route Tables` , and within the TR, we defined the route `0.0.0.0/0` to direct all traffic to the `Internet Gateway` for the Public RT, and `NAT Gateway` for the Private RT. We also created two `subnet association` to associate the route tables to the subnets. Again, we used the `length` function to obtain the number of subnets for each category, and `count` to create a subnet association of each subnet.

Run `terraform plan` and `terraform apply -auto-approve` to inspect and implement the changes.

The Route Tables and the Subnet Association
![alt text](Images/Img_07.png)

The VPC and the current state of the resource map showing how traffic is being routed
![alt text](Images/Img_08.png)

We are now done with the networking aspect of the infrastructure. Now, let's start creating the compute resources. However, before that, we need to step up the necessary user accounts and access control for the resources.

## IaC - IAM Users and Roles

AWS AssumeRole is an AWS Identity and Access Management (IAM) feature that allows an IAM user, AWS service, or federated user to obtain temporary security credentials to access AWS resources securely. This feature is commonly used in scenarios where a user or application requires access to AWS resources in another AWS account or when you need to grant cross-account access.

When a user or application assumes a role, they receive a set of temporary security credentials, including an access key ID, a secret access key, and a session token. These credentials are valid for a limited duration, typically between 15 minutes to 12 hours, depending on how the role is configured. After the duration expires, the credentials are no longer valid, providing an additional layer of security.

To assume a role, the entity must have permission to do so, which is defined in an IAM policy attached to the IAM user, group, or role. The policy must include the sts:AssumeRole action, and it can specify conditions such as the trusted entities (the IAM users or roles that are allowed to assume the role) and the duration for which the credentials are valid.

Once the entity successfully assumes the role, it can use the temporary security credentials to access the AWS resources according to the permissions granted by the role's IAM policies. These temporary credentials are often used in API requests, SDKs, or CLI commands just like regular IAM user credentials.

Now. let's create and AssumeRole for the EC2 Instance

Create a file called `roles.tf` with the code below

> ```bash
> resource "aws_iam_role" "ec2_instance_role" {
>  name = "ec2_instance_role"
>  assume_role_policy = jsonencode({
>    Version = "2012-10-17"
>    Statement = [
>      {
>        Action = "sts:AssumeRole"
>        Effect = "Allow"
>        Sid    = ""
>        Principal = {
>          Service = "ec2.amazonaws.com"
>        }
>      },
>    ]
>  })
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "aws assume role"
>    },
>  )
> }
> ```

The code above creates an IAM role named `ec2_instance_role` and defines a policy that allows EC2 instances to assume this role. This role can then be attached to EC2 instances, granting them permissions to access other AWS services according to the policy `eca.amazonaws.com` attached to this role.

Next, we need to create a Policy and attach it to the role. Still within the `roles.tf` file, add the following lines of code;

> ```bash
> resource "aws_iam_policy" "policy" {
>  name        = "ec2_instance_policy"
>  description = "A test policy"
>  policy = jsonencode({
>    Version = "2012-10-17"
>    Statement = [
>      {
>        Action = [
>          "ec2:Describe*",
>        ]
>        Effect   = "Allow"
>        Resource = "*"
>      },
>    ]
>
>  })
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "aws assume policy"
>    },
>  )
> }
> ```

The code above creates an IAM policy named "ec2_instance_policy" with a description "A test policy". The policy just allows the "ec2:Describe\*" actions on all resources.

Finally, we need to attach the policy to role. To do that, add the following lines of code to the file.

> ```bash
> resource "aws_iam_role_policy_attachment" "test-attach" {
>     role       = aws_iam_role.ec2_instance_role.name
>     policy_arn = aws_iam_policy.policy.arn
> }
> ```

To wrap up the roles and access management section, let's create an Instance Profile as a container for the IAM ROLE. An AWS Instance Profile is an AWS Identity and Access Management (IAM) entity used to provide AWS credentials to an EC2 instance. It is essentially a container for an IAM role that can be associated with an EC2 instance, granting it permissions to interact with other AWS services and resources.

While both AWS AssumeRole and AWS Instance Profile are used to grant permissions within AWS, AssumeRole is primarily used for cross-account access and federated authentication, while Instance Profile is specifically designed for granting permissions to EC2 instances within the same AWS account.

Add the following lines of code to the `roles.tf` file to

> ```bash
> resource "aws_iam_instance_profile" "instance_profile" {
>    name = "aws_instance_profile_test"
>    role =  aws_iam_role.ec2_instance_role.name
> }
> ```

#### Recap

![alt text](Images/diagram.png)

From the diagram above, let's recap on what we've created so far and what's pending. So far, we've created the following:

- [x] The VPC
- [x] Two (2) Public Subnets
- [x] Four (4) Private Subnets
- [x] One (1) Elastic IP
- [x] One (1) Internet Gateway
- [x] One (1) NAT Gateway
- [x] One (1) Public Route Table
  - [x] Two (2) Subnet Associations to the Public Route Table
- [x] One (1) Private Route Table
  - [x] Four (4) Subnet Associations to the Private Route Table
- [x] IAM Roles and Policies for Access Management

Next, we will be creating the Security Groups.

## Creating the Security Groups

Create a new file called `security_groups.tf` with the code below:

> ```bash
> # security group for alb, to allow acess from any where for HTTP and HTTPS traffic
> resource "aws_security_group" "ext-alb-sg" {
>  name        = "ext-alb-sg"
>  vpc_id      = aws_vpc.dio-vpc.id
>  description = "Allow TLS inbound traffic"
>
>  ingress {
>    description = "HTTP"
>    from_port   = 80
>    to_port     = 80
>    protocol    = "tcp"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  ingress {
>    description = "HTTPS"
>    from_port   = 22
>    to_port     = 22
>    protocol    = "tcp"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  egress {
>    from_port   = 0
>    to_port     = 0
>    protocol    = "-1"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_ext-alb-sg"
>    },
>  )
>
> }
>
>
> # security group for bastion, to allow access into the bastion host from you IP
> resource "aws_security_group" "bastion_sg" {
>  name        = "vpc_web_sg"
>  vpc_id      = aws_vpc.dio-vpc.id
>  description = "Allow incoming HTTP connections."
>
>  ingress {
>    description = "SSH"
>    from_port   = 22
>    to_port     = 22
>    protocol    = "tcp"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  egress {
>    from_port   = 0
>    to_port     = 0
>    protocol    = "-1"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_Bastion-SG"
>    },
>  )
> }
>
> #security group for nginx reverse proxy, to allow access only from the external load balancer and bastion instance
> resource "aws_security_group" "nginx-sg" {
>  name   = "nginx-sg"
>  vpc_id = aws_vpc.dio-vpc.id
>
>  egress {
>    from_port   = 0
>    to_port     = 0
>    protocol    = "-1"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_nginx-SG"
>    },
>  )
> }
>
> resource "aws_security_group_rule" "inbound-nginx-http" {
>  type                     = "ingress"
>  from_port                = 443
>  to_port                  = 443
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.ext-alb-sg.id
>  security_group_id        = aws_security_group.nginx-sg.id
> }
>
> resource "aws_security_group_rule" "inbound-bastion-ssh" {
>  type                     = "ingress"
>  from_port                = 22
>  to_port                  = 22
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.bastion_sg.id
>  security_group_id        = aws_security_group.nginx-sg.id
> }
>
> # security group for ialb, to have access only from nginx reverser proxy server
> resource "aws_security_group" "int-alb-sg" {
>  name   = "my-alb-sg"
>  vpc_id = aws_vpc.dio-vpc.id
>
>  egress {
>    from_port   = 0
>    to_port     = 0
>    protocol    = "-1"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_int-alb-sg"
>    },
>  )
>
> }
>
> resource "aws_security_group_rule" "inbound-ialb-https" {
>  type                     = "ingress"
>  from_port                = 443
>  to_port                  = 443
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.nginx-sg.id
>  security_group_id        = aws_security_group.int-alb-sg.id
> }
>
> # security group for webservers, to have access only from the internal load balancer and bastion instance
> resource "aws_security_group" "webserver-sg" {
>  name   = "my-asg-sg"
>  vpc_id = aws_vpc.dio-vpc.id
>
>  egress {
>    from_port   = 0
>    to_port     = 0
>    protocol    = "-1"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_webserver-sg"
>    },
>  )
>
> }
>
> resource "aws_security_group_rule" "inbound-web-https" {
>  type                     = "ingress"
>  from_port                = 443
>  to_port                  = 443
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.int-alb-sg.id
>  security_group_id        = aws_security_group.webserver-sg.id
> }
>
> resource "aws_security_group_rule" "inbound-web-ssh" {
>  type                     = "ingress"
>  from_port                = 22
>  to_port                  = 22
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.bastion_sg.id
>  security_group_id        = aws_security_group.webserver-sg.id
> }
>
> # security group for datalayer to alow traffic from websever on nfs and mysql port and bastion host on mysql port
> resource "aws_security_group" "datalayer-sg" {
>  name   = "datalayer-sg"
>  vpc_id = aws_vpc.dio-vpc.id
>
>  egress {
>    from_port   = 0
>    to_port     = 0
>    protocol    = "-1"
>    cidr_blocks = ["0.0.0.0/0"]
>  }
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_datalayer-sg"
>    },
>  )
> }
>
> resource "aws_security_group_rule" "inbound-nfs-port" {
>  type                     = "ingress"
>  from_port                = 2049
>  to_port                  = 2049
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.webserver-sg.id
>  security_group_id        = aws_security_group.datalayer-sg.id
> }
>
> resource "aws_security_group_rule" "inbound-mysql-bastion" {
>  type                     = "ingress"
>  from_port                = 3306
>  to_port                  = 3306
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.bastion_sg.id
>  security_group_id        = aws_security_group.datalayer-sg.id
> }
>
> resource "aws_security_group_rule" "inbound-mysql-webserver" {
>  type                     = "ingress"
>  from_port                = 3306
>  to_port                  = 3306
>  protocol                 = "tcp"
>  source_security_group_id = aws_security_group.webserver-sg.id
>  security_group_id        = aws_security_group.datalayer-sg.id
> }
> ```

The code above basically creates the security groups that would be required, and provided the ingress and egress rule for the ports that would be allowed to receive traffic.

The Security Groups created
![alt text](Images/Img_09.png)

## Create the Certificate using AWS Certificate Manager

I've already purchased my domain `iamyole.uk` from GoDaddy.com, so we will be issuing a certificate using the AWS Certificate Manager.

Create a file called `cert.tf` with the code below:

> ```bash
> # The entire section creates a certificate, public zone, and validates the certificate using DNS method.
>
> # Create the certificate using a wildcard for all the domains created in iamyole.uk
>
> resource "aws_acm_certificate" "iamyole" {
>  domain_name       = "*.iamyole.uk"
>  validation_method = "DNS"
> }
>
> #creating the hosted zone
> resource "aws_route53_zone" "iamyole" {
>  name = "iamyole"
>
>  tags = merge(
>    var.tags, {
>      Name = "${var.tag_prefix}_Domain"
>    }
>  )
> }
>
> # calling the hosted zone
>  data "aws_route53_zone" "iamyole" {
>   depends_on   = [aws_route53_zone.iamyole]
>   name         = "iamyole.uk"
>   private_zone = false
> }
>
> # selecting validation method
> resource "aws_route53_record" "iamyole" {
>  for_each = {
>    for dvo in aws_acm_certificate.iamyole.domain_validation_options : dvo.domain_name => {
>      name   = dvo.resource_record_name
>      record = dvo.resource_record_value
>      type   = dvo.resource_record_type
>    }
>  }
>
>  allow_overwrite = true
>  name            = each.value.name
>  records         = [each.value.record]
>  ttl             = 60
>  type            = each.value.type
>  zone_id         = data.aws_route53_zone.iamyole.zone_id
> }
>
> # validate the certificate through DNS method
>
> resource "aws_acm_certificate_validation" "iamyole" {
>  certificate_arn         = aws_acm_certificate.iamyole.arn
>  validation_record_fqdns = [for record in aws_route53_record.iamyole : record.fqdn]
> }
>
> # create records for tooling
>
> resource "aws_route53_record" "tooling" {
>  zone_id = data.aws_route53_zone.iamyole.zone_id
>  name    = "tooling.iamyole.uk"
>  type    = "A"
>
>  alias {
>    name                   = aws_lb.ext-alb.dns_name
>    zone_id                = aws_lb.ext-alb.zone_id
>    evaluate_target_health = true
>  }
> }
>
>
> # create records for wordpress
>
> resource "aws_route53_record" "wordpress" {
>  zone_id = data.aws_route53_zone.iamyole.zone_id
>  name    = "wordpress.iamyole.uk"
>  type    = "A"
>
>  alias {
>    name                   = aws_lb.ext-alb.dns_name
>    zone_id                = aws_lb.ext-alb.zone_id
>    evaluate_target_health = true
>  }
> }
> ```

## Creating the Load Balancers, Target Groups and Listeners

First, we will be creating the Application Load Balancer (ALB). Create a file called `alb.tf` with the code:

> ```bash
> resource "aws_lb" "ext-alb" {
>  name     = "ext-alb"
>  internal = false
>  security_groups = [
>       aws_security_group.ext-alb-sg.id,
>     ]
>
>  subnets = [
>    aws_subnet.public[0].id,
>    aws_subnet.public[1].id
>  ]
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_ACS-ext-alb"
>    },
>  )
>
>  ip_address_type    = "ipv4"
>  load_balancer_type = "application"
> }
> ```

The code above creates an application load balancer named `ext-alb`, and configures several properties like the the subnet, ip address type, load balancer type, internal or external etc.

Now in order to direct the ALB n where to route traffic to, we need to create a Target Group. still within the `alb.tf` file, add the following lines of code

> ```bash
> # Creating the Target Group
> resource "aws_lb_target_group" "nginx-tgt" {
>  health_check {
>    interval            = 10
>    path                = "/healthstatus"
>    protocol            = "HTTPS"
>    timeout             = 5
>    healthy_threshold   = 5
>    unhealthy_threshold = 2
>  }
>  name        = "nginx-tgt"
>  port        = 443
>  protocol    = "HTTPS"
>  target_type = "instance"
>  vpc_id      = aws_vpc.dio-vpc.id
> }
> ```

Next, we add a Listener to the Target Group with the code below

> ```bash
> resource "aws_lb_listener" "nginx-listner" {
>  load_balancer_arn = aws_lb.ext-alb.arn
>  port              = 443
>  protocol          = "HTTPS"
>  certificate_arn   = aws_acm_certificate_validation.iamyole.certificate_arn
>
>  default_action {
>    type             = "forward"
>    target_group_arn = aws_lb_target_group.nginx-tgt.arn
>  }
> }
> ```

Finally, since we won't be connecting to the Web Applications with the Server IP, we need save the ALB DNS name. Add the following lines of code to `alb.tf` file to print out the DNS name.

> ```bash
> output "alb_dns_name" {
>  value = aws_lb.ext-alb.dns_name
> }
>
> output "alb_target_group_arn" {
>  value = aws_lb_target_group.nginx-tgt.arn
> }
> ```

Next, within the same file, let's create the Internal Load Balancer for the web servers

> ```bash
> # ----------------------------
> #Internal Load Balancers for webservers
> #---------------------------------
>
> resource "aws_lb" "ialb" {
>  name     = "ialb"
>  internal = true
>  security_groups = [
>    aws_security_group.int-alb-sg.id,
>  ]
>
>  subnets = [
>    aws_subnet.private[0].id,
>    aws_subnet.private[1].id
>  ]
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "ACS-int-alb"
>    },
>  )
>
>  ip_address_type    = "ipv4"
>  load_balancer_type = "application"
> }
> ```

Again, we create the Target Group for the web servers and route traffic from the internal ALB to the traffic group

> ```bash
> # --- target group  for wordpress -------
>
> resource "aws_lb_target_group" "wordpress-tgt" {
>  health_check {
>    interval            = 10
>    path                = "/healthstatus"
>    protocol            = "HTTPS"
>    timeout             = 5
>    healthy_threshold   = 5
>    unhealthy_threshold = 2
>  }
>
>  name        = "wordpress-tgt"
>  port        = 443
>  protocol    = "HTTPS"
>  target_type = "instance"
>  vpc_id      = aws_vpc.dio-vpc.id
> }
>
>
> # --- target group for tooling -------
>
> resource "aws_lb_target_group" "tooling-tgt" {
>  health_check {
>    interval            = 10
>    path                = "/healthstatus"
>    protocol            = "HTTPS"
>    timeout             = 5
>    healthy_threshold   = 5
>    unhealthy_threshold = 2
>  }
>
>  name        = "tooling-tgt"
>  port        = 443
>  protocol    = "HTTPS"
>  target_type = "instance"
>  vpc_id      = aws_vpc.dio-vpc.id
> }
> ```

Now, we need to create a listener and add it to the Load Balancer

> ```bash
> # For this aspect a single listener was created for the wordpress which is default,
> # A rule was created to route traffic to tooling when the host header changes
>
> resource "aws_lb_listener" "web-listener" {
>  load_balancer_arn = aws_lb.ialb.arn
>  port              = 443
>  protocol          = "HTTPS"
>  certificate_arn   = aws_acm_certificate_validation.iamyole.certificate_arn
>
>  default_action {
>    type             = "forward"
>    target_group_arn = aws_lb_target_group.wordpress-tgt.arn
>  }
> }
>
> # listener rule for tooling target
>
> resource "aws_lb_listener_rule" "tooling-listener" {
>  listener_arn = aws_lb_listener.web-listener.arn
>  priority     = 99
>
>  action {
>    type             = "forward"
>    target_group_arn = aws_lb_target_group.tooling-tgt.arn
>  }
>
>  condition {
>    host_header {
>      values = ["tooling.iamyole.uk"]
>    }
>  }
> }
> ```

We've now written the code to create the DNS Zone (ROute53), The Certificate, The Load Balancers, Target Groups and the Listeners. Now, let's validate the code is void of any syntax errors and then implement the changes.

The codes are validated
![alt text](Images/Img_10.png)

Now, let's `terraform plan` to inspect the changes
![alt text](Images/Img_11.png)

From the output above, 14 new resources would be created, 0 deleted and 0 modified. We can delay the implementation for now until we've created more resources. That way, we won't have any resource created and idle.

## Creating the Auto Scaling Group, SNS, and Launch Template

In this section, we will be creating the Auto Scaling Groups for the nginx, tooling, bastion and web server. The ASG would automatically increase (scale up) or decrease (scale down) the number of Instances required at any point in time depending on traffic/resource utilization. However, before we do this, we need to create a launch template with pre-defined settings to automatically spin the instances as required.

To accomplish this, we will be creating two files `asg-bastion-nginx.tf` and `asg-tooling-wordpress.tf`.

Let's start with creating some new variables that would be used in the files above. Edit the `variables.tf` and add the following lines

> ```bash
> variable "ami_RHEL_9" {
>  default = "ami-0fe630eb857a6ec83"
> }
> variable "ami_Ubuntu_Sever_22" {
>  default = "ami-080e1f13689e07408"
> }
> variable "instance_type" {
>  default = "t2.micro"
> }
> variable "keypair" {
>  default = "ytech-key"
> }
> ```

Next, create a new folder in the root directory called `userdata`. Within the folder, create the following files, and populate it with the script as follows.

- `bastion.sh`

  > ```bash
  > #!/bin/bash
  > # Update package lists and install required packages
  > yum update -y
  >
  > # Install Git and Ansible
  > yum install -y git ansible-core python ntp net-tools vim wget telnet chrony
  >
  > # Start and enable the NTP service
  > systemctl start chronyd
  > systemctl enable chronyd
  > ```

- `nginx.sh`

  > ```bash
  > #!/bin/bash
  > # Update package lists and install required packages
  > yum update -y
  >
  > # Install required packages
  > yum install -y python ntp net-tools vim wget telnet chrony nginx-all-modules.noarch
  >
  > # Start and enable the NTP service
  > systemctl start chronyd
  > systemctl enable chronyd
  >
  > # Start and enable the NGINX service
  > systemctl start nginx
  > systemctl enable nginx
  > ```

- `tooling.sh`

  > ```bash
  > #!/bin/bash
  >
  > # Update package lists
  > sudo apt update
  >
  > # Install required packages
  > sudo apt install -y python3 ntp net-tools vim wget git htop php
  >
  > # Cloning the tooling site
  > git clone https://github.com/darey-io/tooling.git
  >
  > # Move the Web Files to the html directory
  > cd tooling/html
  > cp -R  * /var/www/html
  > ```

- `wordpress.sh`
  > ```bash
  > #!/bin/bash
  >
  > # Update package lists
  > sudo apt update
  >
  > # Install required packages
  > sudo apt install -y python ntp net-tools vim wget git htop php
  >
  > # Install WordPress and its dependencies
  > sudo apt install -y wordpress
  >
  > ```

Now, we can start creating the files starting with `asg-bastion-nginx.tf`

> ```bash
> # creating sns topic for all the auto scaling groups
> resource "aws_sns_topic" "iamyole-sns" {
>  name = "Default_CloudWatch_Alarms_Topic"
> }
>
> # creating notification for all the auto scaling groups
> resource "aws_autoscaling_notification" "iamyole_notifications" {
>  group_names = [
>    aws_autoscaling_group.bastion-asg.name,
>    aws_autoscaling_group.nginx-asg.name,
>    aws_autoscaling_group.wordpress-asg.name,
>    aws_autoscaling_group.tooling-asg.name,
>  ]
>  notifications = [
>    "autoscaling:EC2_INSTANCE_LAUNCH",
>    "autoscaling:EC2_INSTANCE_TERMINATE",
>    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
>    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
>  ]
>
>  topic_arn = aws_sns_topic.iamyole-sns.arn
> }
>
> resource "random_shuffle" "az_list" {
>  input = data.aws_availability_zones.available.names
> }
>
> # launch template for bastion
>
> resource "aws_launch_template" "bastion-launch-template" {
>  image_id               = var.ami_RHEL_9
>  instance_type          = var.instance_type
>  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
>
>  /*   iam_instance_profile {
>    name = aws_iam_instance_profile.ip.id
>  } */
>
>  key_name = var.keypair
>
>  placement {
>    availability_zone = "random_shuffle.az_list.result"
>  }
>
>  lifecycle {
>    create_before_destroy = true
>  }
>
>  tag_specifications {
>    resource_type = "instance"
>
>    tags = merge(
>      var.tags,
>      {
>        Name = "${var.tag_prefix}_bastion-launch-template"
>      },
>    )
>  }
>
>  user_data = filebase64("${path.module}/userdata/bastion.sh")
> }
>
> # ---- Autoscaling for bastion  hosts
>
> resource "aws_autoscaling_group" "bastion-asg" {
>  name                      = "bastion-asg"
>  max_size                  = 2
>  min_size                  = 1
>  health_check_grace_period = 300
>  health_check_type         = "ELB"
>  desired_capacity          = 1
>
>  vpc_zone_identifier = [
>    aws_subnet.public[0].id,
>    aws_subnet.public[1].id
>  ]
>
>  launch_template {
>    id      = aws_launch_template.bastion-launch-template.id
>    version = "$Latest"
>  }
>  tag {
>    key                 = "Name"
>    value               = "bastion-launch-template"
>    propagate_at_launch = true
>  }
>
> }
>
> # launch template for nginx
>
> resource "aws_launch_template" "nginx-launch-template" {
>  image_id               = var.ami_RHEL_9
>  instance_type          = var.instance_type
>  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
>
>  /*  iam_instance_profile {
>    name = aws_iam_instance_profile.ip.id
>  } */
>
>  key_name = var.keypair
>
>  placement {
>    availability_zone = "random_shuffle.az_list.result"
>  }
>
>  lifecycle {
>    create_before_destroy = true
>  }
>
>  tag_specifications {
>    resource_type = "instance"
>
>    tags = merge(
>      var.tags,
>      {
>        Name = "${var.tag_prefix}_nginx-launch-template"
>      },
>    )
>  }
>
>  user_data = filebase64("${path.module}/userdata/nginx.sh")
> }
>
> # ------ Autoscslaling group for reverse proxy nginx ---------
>
> resource "aws_autoscaling_group" "nginx-asg" {
>  name                      = "nginx-asg"
>  max_size                  = 2
>  min_size                  = 1
>  health_check_grace_period = 300
>  health_check_type         = "ELB"
>  desired_capacity          = 1
>
>  vpc_zone_identifier = [
>    aws_subnet.public[0].id,
>    aws_subnet.public[1].id
>  ]
>
>  launch_template {
>    id      = aws_launch_template.nginx-launch-template.id
>    version = "$Latest"
>  }
>
>  tag {
>    key                 = "Name"
>    value               = "nginx-launch-template"
>    propagate_at_launch = true
>  }
>
> }
>
> # attaching autoscaling group of nginx to external load balancer
> resource "aws_autoscaling_attachment" "asg_attachment_nginx" {
>  autoscaling_group_name = aws_autoscaling_group.nginx-asg.id
>  lb_target_group_arn    = aws_lb_target_group.nginx-tgt.arn
> }
> ```

Next, we create the `asg-tooling-wordpress.tf`

> ```bash
> # launch template for wordpress
>
> resource "aws_launch_template" "wordpress-launch-template" {
>  image_id               = var.ami_Ubuntu_Sever_22
>  instance_type          = var.instance_type
>  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
>
>  /*   iam_instance_profile {
>    name = aws_iam_instance_profile.ip.id
>  } */
>
>  key_name = var.keypair
>
>  placement {
>    availability_zone = "random_shuffle.az_list.result"
>  }
>
>  lifecycle {
>    create_before_destroy = true
>  }
>
>  tag_specifications {
>    resource_type = "instance"
>
>    tags = merge(
>      var.tags,
>      {
>        Name = "${var.tag_prefix}_wordpress-launch-template"
>      },
>    )
>
>  }
>
>  user_data = filebase64("${path.module}/userdata/wordpress.sh")
> }
>
> # ---- Autoscaling for wordpress application
>
> resource "aws_autoscaling_group" "wordpress-asg" {
>  name                      = "wordpress-asg"
>  max_size                  = 2
>  min_size                  = 1
>  health_check_grace_period = 300
>  health_check_type         = "ELB"
>  desired_capacity          = 1
>  vpc_zone_identifier = [
>
>    aws_subnet.private[0].id,
>    aws_subnet.private[1].id
>  ]
>
>  launch_template {
>    id      = aws_launch_template.wordpress-launch-template.id
>    version = "$Latest"
>  }
>  tag {
>    key                 = "Name"
>    value               = "wordpress-asg"
>    propagate_at_launch = true
>  }
> }
>
> # attaching autoscaling group of wordpress application to internal loadbalancer
> resource "aws_autoscaling_attachment" "asg_attachment_wordpress" {
>  autoscaling_group_name = aws_autoscaling_group.wordpress-asg.id
>  lb_target_group_arn    = aws_lb_target_group.wordpress-tgt.arn
> }
>
> # launch template for tooling
> resource "aws_launch_template" "tooling-launch-template" {
>  image_id               = var.ami_Ubuntu_Sever_22
>  instance_type          = var.instance_type
>  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
>
>  /*   iam_instance_profile {
>    name = aws_iam_instance_profile.ip.id
>  } */
>
>  key_name = var.keypair
>
>  placement {
>    availability_zone = "random_shuffle.az_list.result"
>  }
>
>  lifecycle {
>    create_before_destroy = true
>  }
>
>  tag_specifications {
>    resource_type = "instance"
>
>    tags = merge(
>      var.tags,
>      {
>        Name = "${var.tag_prefix}_tooling-launch-template"
>      },
>    )
>
>  }
>
>  user_data = filebase64("${path.module}/userdata/tooling.sh")
> }
>
> # ---- Autoscaling for tooling -----
>
> resource "aws_autoscaling_group" "tooling-asg" {
>  name                      = "tooling-asg"
>  max_size                  = 2
>  min_size                  = 1
>  health_check_grace_period = 300
>  health_check_type         = "ELB"
>  desired_capacity          = 1
>
>  vpc_zone_identifier = [
>
>    aws_subnet.private[0].id,
>    aws_subnet.private[1].id
>  ]
>
>  launch_template {
>    id      = aws_launch_template.tooling-launch-template.id
>    version = "$Latest"
>  }
>
>  tag {
>    key                 = "Name"
>    value               = "tooling-launch-template"
>    propagate_at_launch = true
>  }
> }
>
> # attaching autoscaling group of  tooling application to internal loadbalancer
> resource "aws_autoscaling_attachment" "asg_attachment_tooling" {
>  autoscaling_group_name = aws_autoscaling_group.tooling-asg.id
>  lb_target_group_arn    = aws_lb_target_group.tooling-tgt.arn
> }
> ```

Again, to confirm the code is void of syntax errors, run `terraform validate` and then `terraform plan`.

## Storage Layer and Encryption

In this section, we will be creating AWS Elastic File System, Key Management System and the RDS.

Let's start with the Key Management System. Create a file called `efs.tf`

> ```bash
> # create key from key management system
> resource "aws_kms_key" "ACS-kms" {
>  description = "KMS key "
>  policy      = <<EOF
>  {
>  "Version": "2012-10-17",
>  "Id": "kms-key-policy",
>  "Statement": [
>    {
>      "Sid": "Enable IAM User Permissions",
>      "Effect": "Allow",
>      "Principal": { "AWS": "arn:aws:iam::${var.account_id}:user/aws-iamYole" },
>      "Action": "kms:*",
>      "Resource": "*"
>    }
>  ]
> }
> EOF
> }
>
> # create key alias
> resource "aws_kms_alias" "alias" {
>  name          = "alias/kms"
>  target_key_id = aws_kms_key.ACS-kms.key_id
> }
> ```

Update the `variables.tf` file with the account_id variable. Please note that this should your AWS Account ID.

Still in the `efs.tf` file, let's create the Elastic File System with the code below

> ```bash
> # create Elastic file system
> resource "aws_efs_file_system" "ACS-efs" {
>  encrypted  = true
>  kms_key_id = aws_kms_key.ACS-kms.arn
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "ACS-efs"
>    },
>  )
> }
>
> # set first mount target for the EFS
> resource "aws_efs_mount_target" "subnet-1" {
>  file_system_id  = aws_efs_file_system.ACS-efs.id
>  subnet_id       = aws_subnet.private[2].id
>  security_groups = [aws_security_group.datalayer-sg.id]
> }
>
> # set second mount target for the EFS
> resource "aws_efs_mount_target" "subnet-2" {
>  file_system_id  = aws_efs_file_system.ACS-efs.id
>  subnet_id       = aws_subnet.private[3].id
>  security_groups = [aws_security_group.datalayer-sg.id]
> }
>
> # create access point for wordpress
> resource "aws_efs_access_point" "wordpress" {
>  file_system_id = aws_efs_file_system.ACS-efs.id
>
>  posix_user {
>    gid = 0
>    uid = 0
>  }
>
>  root_directory {
>    path = "/wordpress"
>
>    creation_info {
>      owner_gid   = 0
>      owner_uid   = 0
>      permissions = 0755
>    }
>
>  }
>
> }
>
>
> # create access point for tooling
> resource "aws_efs_access_point" "tooling" {
>  file_system_id = aws_efs_file_system.ACS-efs.id
>  posix_user {
>    gid = 0
>    uid = 0
>  }
>
>  root_directory {
>
>    path = "/tooling"
>
>    creation_info {
>      owner_gid   = 0
>      owner_uid   = 0
>      permissions = 0755
>    }
>
>  }
> }
> ```

Finally, let's create the `rds.tf` file

> ```bash
> # This section will create the subnet group for the RDS instance using the private subnet
> resource "aws_db_subnet_group" "ACS-rds" {
>  name       = "acs-rds"
>  subnet_ids = [aws_subnet.private[2].id, aws_subnet.private[3].id]
>
>  tags = merge(
>    var.tags,
>    {
>      Name = "${var.tag_prefix}_ACS-rds"
>    },
>  )
> }
>
> # create the RDS instance with the subnets group
> resource "aws_db_instance" "ACS-rds" {
>  allocated_storage      = 20
>  storage_type           = "gp2"
>  engine                 = "mysql"
>  engine_version         = "5.7"
>  instance_class         = "db.t3.micro"
>  db_name                = var.db_name
>  username               = var.master-username
>  password               = var.master-password
>  parameter_group_name   = "default.mysql5.7"
>  db_subnet_group_name   = aws_db_subnet_group.ACS-rds.name
>  skip_final_snapshot    = true
>  vpc_security_group_ids = [aws_security_group.datalayer-sg.id]
>  multi_az               = "true"
> }
> ```

Add the username and password variables to the variables file

> ```bash
> variable "db_name" {
>  type = string
> }
> variable "master-username" {
>  type = string
> }
> variable "master-password" {
>  type = string
> }
> ```

and then the `terraform.tfvars`

> ```bash
> master-username = "dbadmin"
>
> master-password = "P@ssw0rd1"
>
> db_name = "diobd"
> ```

## Implementing the Code

The code for all the resources have been created now. Let's perform the necessary validation checks to ensure no syntax errors. Note, you may need to run `terraform init` again as we introduced the `random shuffle` module.

![alt text](Images/Img_12.png)

Now, `terraform plan -out=tfplan.out` to inspect all the changes

44 Changes or resources to be created
![alt text](Images/Img_13.png)

As we had no errors with the code, let's run `terraform apply -auto-approve` to execute the changes.

The infrastructure has now been created. We can log in to the AWS Console to verify the resources.

The load balancers
![alt text](Images/Img_14.png)

The Auto Scaling Groups
![alt text](Images/Img_15.png)

The instances created from the templates
![alt text](Images/Img_16.png)

The RDS
![alt text](Images/Img_18.png)
We can also run `terraform state list` from the console to view the state of all terraform created resources.

List of resources
![alt text](Images/Img_19.png)

We can also run `terraform destroy -target=[resource.name]` to delete a resource or `terraform destroy` to delete all resources.

Earlier, we ran `terraform plan -out=tfplan.out` to save the configuration file. We can now safely run `terraform destroy` to delete all resources to avoid huge cost at the end of the month.
