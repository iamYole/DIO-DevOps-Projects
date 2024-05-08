# Building an EKS Kubernetes Cluster with Terraform

In previous projects, we built a Kubernetes Cluster from ground up, seen how to easily spin up a k8r cluster using EKS, deployed a simple 1 pod application and dived a little into data persistence in a k8r cluster. This project will solidify our understanding of what we've learnt so far and introduce now topics like:

- Using Terraform to create an EKS cluster and dynamically add scalable nodes
- Deploy multiple applications to a cluster using Helm
- Explore more objects in K8r
- Integrate Jenkins to the deployment of application on a kubernetes cluster.

lets start by creating the K8r

## Building an EKS Cluster with Terraform

Before we begin, lets ensure we have access to an S3 Bucket to store the terraform state file

- Create a home directory for this project
- Within the directory, create a file called `variables.tf` with the code below:

  > ```json
  > variable "cluster_name" {
  >    type        = string
  >    description = "EKS cluster name."
  > }
  > variable "iac_environment_tag" {
  >    type        = string
  >    description = "AWS tag to indicate environment name of each infrastructure object."
  > }
  > variable "name_prefix" {
  >    type        = string
  >    description = "Prefix to be used on each infrastructure object Name created in AWS."
  > }
  > variable "main_network_block" {
  >    type        = string
  >    description = "Base CIDR block to be used in our VPC."
  > }
  > variable "subnet_prefix_extension" {
  >    type        = number
  >    description = "CIDR block bits extension to calculate CIDR blocks of each subnetwork."
  > }
  > variable "zone_offset" {
  >    type        = number
  >    description = "CIDR block bits extension offset to calculate Public subnets, avoiding collisions with Private subnets."
  > }
  > ```

- Within the directory create a file `backend.tf` with the code below:
  > ```json
  > ## Configure S3 Backend
  > terraform {
  >  backend "s3" {
  >    bucket         = "ytech-terraform-state"
  >    key            = "eks/s3/terraform.tfstate"
  >    region         = "us-east-2"
  >    encrypt        = true
  >  }
  > }
  > ```
- Create a file – network.tf and provision Elastic IP for Nat Gateway, VPC, Private and public subnets.  
  We be using the official AWS module to create the VPC.

  > ```json
  > # reserve Elastic IP to be used in our NAT gateway
  > resource "aws_eip" "nat_gw_elastic_ip" {
  > vpc = true
  >
  > tags = {
  >    Name            = "${var.cluster_name}-nat-eip"
  >    iac_environment = var.iac_environment_tag
  >    }
  >  }
  >
  > # Create VPC using the official AWS module
  > module "vpc" {
  > source  = "terraform-aws-modules/vpc/aws"
  >
  > name = "${var.name_prefix}-vpc"
  > cidr = var.main_network_block
  > azs  = data.aws_availability_zones.available_azs.names
  >
  > private_subnets = [
  >    # this loop will create a one-line list as ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20", ...]
  >    # with a length depending on how many Zones are available
  >    for zone_id in data.aws_availability_zones.available_azs.zone_ids :
  >        cidrsubnet(var.main_network_block, var.subnet_prefix_extension, tonumber(substr(zone_id, length(zone_id) - 1, 1)) - 1)
  > ]
  >
  > public_subnets = [
  >    # this loop will create a one-line list as ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20", ...]
  >    # with a length depending on how many Zones are available
  >    # there is a zone Offset variable, to make sure no collisions are present with private subnet blocks
  >    for zone_id in data.aws_availability_zones.available_azs.zone_ids :
  >        cidrsubnet(var.main_network_block, var.subnet_prefix_extension, tonumber(substr(zone_id, length(zone_id) - 1, 1)) + var.zone_offset - 1)
  > ]
  >
  > # Enable single NAT Gateway to save some money
  > # WARNING: this could create a single point of failure, since we are creating a NAT Gateway in one AZ only
  > # reference: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.44.0#nat-gateway-scenarios
  > enable_nat_gateway     = true
  > single_nat_gateway     = true
  > one_nat_gateway_per_az = false
  > enable_dns_hostnames   = true
  > reuse_nat_ips          = true
  > external_nat_ip_ids    = [aws_eip.nat_gw_elastic_ip.id]
  >
  > # Add VPC/Subnet tags required by EKS
  > tags = {
  >    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  >    iac_environment                             = var.iac_environment_tag
  >    }
  > public_subnet_tags = {
  >    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  >    "kubernetes.io/role/elb"                    = "1"
  >    iac_environment                             = var.iac_environment_tag
  >    }
  > private_subnet_tags = {
  >    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  >    "kubernetes.io/role/internal-elb"           = "1"
  >    iac_environment                             = var.iac_environment_tag
  >    }
  >  }
  >    Note: The tags added to the subnets is very important. The Kubernetes Cloud Controller Manager (cloud-controller-manager) and AWS Load Balancer Controller (aws-load-balancer-controller) needs to identify the cluster’s. To do that, it queries the cluster’s subnets by using the tags as a filter.
  > ```

  - For public and private subnets that use load balancer resources: each subnet must be tagged  
    **Key: kubernetes.io/cluster/cluster-name Value: shared**

  - For private subnets that use internal load balancer resources: each subnet must be tagged  
    **Key: kubernetes.io/role/internal-elb Value: 1**

  - For public subnets that use internal load balancer resources: each subnet must be tagged  
    **Key: kubernetes.io/role/elb Value: 1**

- Create a file – data.tf – This will pull the available AZs for use.

  > ```json
  > # get all available AZs in the region
  > data "aws_availability_zones" "available_azs" {
  >    state = "available"
  > }
  >
  > # obtain the account id
  > data "aws_caller_identity" "current" {}
  > ```

- Create the `main.tf` to provision the EKS cluster using the EKS Module.  
  Read more about this module from the official documentation [here](https://github.com/terraform-aws-modules/terraform-aws-eks)
  > ```json
  > module "eks_cluster" {
  >      source  = "terraform-aws-modules/eks/aws"
  >      version = "~> 18.0"
  >      cluster_name    = var.cluster_name
  >      cluster_version = "1.22"
  >      vpc_id     = module.vpc.vpc_id
  >      subnet_ids = module.vpc.private_subnets
  >      cluster_endpoint_private_access = true
  >      cluster_endpoint_public_access = true
  >
  > # Self Managed Node Group(s)
  >      self_managed_node_group_defaults = {
  >          instance_type                          = var.asg_instance_types[0]
  >          update_launch_template_default_version = true
  >      }
  >      self_managed_node_groups = local.self_managed_node_groups
  >
  > # aws-auth configmap
  >      create_aws_auth_configmap = true
  >      manage_aws_auth_configmap = true
  >      aws_auth_users = concat(local.admin_user_map_users, local.developer_user_map_users)
  >      tags = {
  >          Environment = "prod"
  >          Terraform   = "true"
  >      }
  > }
  > ```
- Create a file – `locals.tf` to create local variables.
  > ```json
  > # render Admin & Developer users list with the structure required by EKS module
  > locals {
  >  admin_user_map_users = [
  >    for admin_user in var.admin_users :
  >    {
  >      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"
  >      username = admin_user
  >      groups   = ["system:masters"]
  >    }
  >  ]
  >  developer_user_map_users = [
  >    for developer_user in var.developer_users :
  >    {
  >      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${developer_user}"
  >      username = developer_user
  >      groups   = ["${var.name_prefix}-developers"]
  >    }
  >  ]
  >
  >  self_managed_node_groups = {
  >    worker_group1 = {
  >      name = "${var.cluster_name}-wg"
  >
  >      min_size      = var.autoscaling_minimum_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
  >      desired_size      = var.autoscaling_minimum_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
  >      max_size  = var.autoscaling_maximum_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
  >      instance_type = var.asg_instance_types[0].instance_type
  >
  >      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
  >
  >      block_device_mappings = {
  >        xvda = {
  >          device_name = "/dev/xvda"
  >          ebs = {
  >            delete_on_termination = true
  >            encrypted             = false
  >            volume_size           = 10
  >            volume_type           = "gp2"
  >          }
  >        }
  >      }
  >
  >      use_mixed_instances_policy = true
  >      mixed_instances_policy = {
  >        instances_distribution = {
  >          spot_instance_pools = 4
  >        }
  >
  >        override = var.asg_instance_types
  >      }
  >    }
  >  }
  > }
  > ```
- Add more variables to the `variables.tf` file

  > ```json
  > variable "admin_users" {
  >  type        = list(string)
  >  description = "List of Kubernetes admins."
  > }
  > variable "developer_users" {
  >  type        = list(string)
  >  description = "List of Kubernetes developers."
  > }
  > variable "asg_instance_types" {
  >  description = "List of EC2 instance machine types to be used in EKS."
  > }
  > variable "autoscaling_minimum_size_by_az" {
  >  type        = number
  >  description = "Minimum number of EC2 instances to autoscale our EKS cluster on each AZ."
  > }
  > variable "autoscaling_maximum_size_by_az" {
  >  type        = number
  >  description = "Maximum number of EC2 instances to autoscale our EKS cluster on each AZ."
  > }
  > ```

- Create a file – `auto.terraform.tfvars` to set values for variables.
