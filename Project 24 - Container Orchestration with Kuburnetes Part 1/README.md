# Container Orchestration with Kubernetes Part 1

In previous projects, we learnt about containers, it's usefulness, and how to containerize applications. In this project, we will be introduce to Container Orchestration and Kubernetes.

## **What is Container Orchestration**

Container Orchestration is the automated management and coordination of containerized applications which involves deploying, scaling, updating, and managing containers across a cluster of servers. There are several container orchestration platforms in the market Kubernetes, Docker Swarm, and Apache Mesos, and these softwares will be responsible for the orchestration of the containers. Kubernetes is the market leader in this category, and that's what we would be working with in this project.

**Kubernetes**, often abbreviated as K8s, is an open-source container orchestration platform originally developed by Google and now maintained by the Cloud Native Computing Foundation (CNCF). Kubernetes provides a platform for orchestrating containers, enabling efficient resource utilization, seamless scaling, and high availability.

### **The Kubernetes architecture**

Kubernetes is designed around a master-slave model, with a master node orchestrating multiple worker nodes.

![alt text](Images/Img_02.png)

At the heart of the architecture lies the **Kubernetes master**, which consists of several components:

- **API Server**: The API Server acts as the frontend for the Kubernetes control plane. It validates and processes RESTful API requests, serving as the primary entry point for all administrative tasks.
- **Scheduler**: Responsible for placing containers onto available nodes in the cluster based on resource requirements, workload constraints, and other policies.
- **Controller Manager**: Manages various controllers that regulate the state of the cluster, ensuring that the desired state matches the actual state and initiating corrective actions when necessary.
- **etcd**: A distributed key-value store that stores all cluster data, including configuration details, cluster state, and metadata. It serves as the Kubernetes' backing store for all cluster data.

On the **Kubernetes worker nodes**, the following components run:

- **Kubelet**: An agent that runs on each node and is responsible for communicating with the Kubernetes master. It manages containers on the node, ensuring that they are running and healthy.
- **Kube-proxy**: Maintains network rules on the host and performs connection forwarding for Kubernetes services. It enables communication between services within the cluster and from external clients to services running on the cluster.
- **Container Runtime**: The software responsible for running containers, such as Docker or containerd. It manages the lifecycle of containers, including starting, stopping, and managing their resources.

These components work together to provide the foundation for container orchestration in Kubernetes, enabling the deployment, scaling, and management of containerized applications across clusters of nodes.

![alt text](Images/Img_01.png)

I'll recommend you read more about these components and how the function from the Kubernetes official documentation [here](https://kubernetes.io/docs/concepts/overview/components/)

## Installing Kubernetes (k8s) from scratch

Installing and configuring a K8s cluster from scratch in a production or Corporate environment is quite a task especially when considering security and scalability of the environment. Luckily, there are managed versions of k8s already created by some software giants: Amazon Elastic Kubernetes Services (Amazon EKS), Google Kubernetes Engine (GKE) and Azure Kubernetes Services (AKS). There are also open source tools for running k8s locally or in a development environment as minikube, MicroK8s, K3s, etc.

In this project, we will be doing it the hard way initially so as to fully understand each component and how they fit together to form a fully working K8s cluster. As a Kubernetes Administrator, you would be charged with the following responsibilities and more:

1. Install and configure master (also known as control plane) components and worker nodes (or just nodes).
2. Apply security settings across the entire cluster (i.e., encrypting the data in transit, and at rest)
   - In transit encryption means encrypting communications over the network using HTTPS
   - At rest encryption means encrypting the data stored on a disk
3. Plan the capacity for the backend data store etcd
4. Configure network plugins for the containers to communicate
5. Manage periodical upgrade of the cluster
6. Configure observability/monitoring and auditing

`Note: Unless you have any business or compliance restrictions, ALWAYS consider to use managed versions of K8s – Platform as a Service offerings, such as Azure Kubernetes Service (AKS), Amazon Elastic Kubernetes Service (Amazon EKS), or Google Kubernetes Engine (GKE) as they usually have better default security settings, and the costs for maintaining the control plane are very low.`

### Let us begin building out Kubernetes cluster from the ground

**DISCLAIMER**: The following setup of Kubernetes should be used for learning purpose only, and not to be considered for production. This is because setting up a K8s cluster for production use has a lot more moving parts, especially when it comes to planning the nodes, and securing the cluster. The purpose of "K8s From-Ground-Up" is to get you much closer to the different components as shown in the architecture diagram and relate with what you have been learning about Kubernetes.

The following tools and packages would be required in this project:

- Virtual Machines: AWS EC2 (3) One master and 2 nodes
- AWS CLI
- Docker Engine: To build/run individual containers
- kubectl console utility
- cfssl and cfssljson utilities
- Kubernetes cluster

We will be creating 3 EC2 Instances and then make the following configurations:

- SSL/TLS certificates for Kubernetes components to communicate securely
- Configured Node Network
- Configured Pod Network

## Preparing the Setup Environment

The set up environment would be pretty simple. An EC2 Instance running Ubuntu 22 and the software packages listed above.

- Provision an EC2 Instance running Ubuntu 22
- Install the following:
  - sudo apt update
  - sudo apt install awscli -y
  - sudo apt install jq -y  
    `'jq' is a lightweight and flexible command-line tool for parsing, manipulating, and querying JSON data`
- Next, we configure awscli with the necessary credentials

  - run `aws configure` and then provide the details requested by the prompt
  - run `aws ec2 describe-vpcs` to confirm aws has been configured successfully with the right credentials

    ![alt text](Images/Img_03.png)

- Install `kubectl`

  - Download the binary file: `wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl`
  - Make it executable: `chmod +x kubectl`
  - Move it to the bin directory, making the command globally recognized in the system: `sudo mv kubectl /usr/local/bin/`
  - Verify `kubectl` has been installed correctly: `kubectl version --short`

    ![alt text](Images/Img_04.png)

- Install CFSSL and CFSSLJSON-linux  
  CFSSL is an open source tool by Cloudflare used to setup a Public Key Infrastructure (PKI) for generating, signing and bundling TLS certificates. cfssl will be configured as a Certificate Authority which will issue the certificates required to spin up the Kubernetes cluster.

  > ```bash
  > wget -q --show-progress --https-only --timestamping \
  > https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  > https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  >
  > chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
  > sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
  > sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  > ```

- Verify it's installation

  > `cfssl version`

  ![alt text](Images/Img_05.png)

## Provisioning the AWS Resources using AWSCLI

When working with Kubernetes on AWS, it's often recommended to create the Kubernetes cluster in a separate VPC rather than the default VPC provided by AWS. This recommendation is down to the following reasons:

- **Isolation**: Creating the Kubernetes cluster in a separate VPC provides isolation from other resources in the default VPC. This isolation can enhance security and prevent unintended interactions between resources.
- **Control**: By creating a dedicated VPC for the Kubernetes cluster, you have more control over the network configuration, security settings, and routing policies specific to the cluster's requirements. This allows for better customization and optimization of network resources.
- **Avoiding Conflicts**: Running Kubernetes in a separate VPC helps avoid potential conflicts with existing resources or configurations in the default VPC. It allows you to tailor the network environment specifically for Kubernetes workloads without impacting other AWS resources.

## Creating the VPC and Network resources

Create a directory called `k8s-cluster-from-ground-up`

### Virtual Private Cloud (VPC)

- Create the VPC:
  - `VPC_ID=$(aws ec2 create-vpc --cidr-block 172.31.0.0/16 --output text --query 'Vpc.VpcId')`
- Create a variable called NAME:
  - `NAME=k8s-cluster`
- Create a variable called AWS_REGION:
  - `AWS_REGION=us-east-2`
- Tag the VPC with the name variable:

  - `aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=${NAME}`

  ![alt text](Images/Img_06.png)
  Notice that `DNS` is currently disabled

### Domain Name System – DNS

- Enable DNS support for the VPC:
  - `aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'`
- Enable DNS support for hostnames:

  - `aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'`

  ![alt text](Images/Img_07.png)

### Dynamic Host Configuration Protocol – DHCP

DHCP options sets are configurations that allow you to specify custom DHCP options for your AWS Virtual Private Cloud (VPC). These options are used to configure instances with custom DNS servers, domain names, NTP (Network Time Protocol) servers, NetBIOS name servers, and more.

AWS automatically creates and associates a DHCP option set for your VPC upon creation and sets two options: domain-name-servers (defaults to AmazonProvidedDNS) and domain-name (defaults to the domain name for your set region). AmazonProvidedDNS is an Amazon Domain Name System (DNS) server, and this option enables DNS for instances to communicate using DNS names. By default, EC2 instances have fully qualified names like` ip-172-50-197-106.eu-central-1.compute.internal`. But you can set your own configuration using an example below:

> ```bash
> DHCP_OPTION_SET_ID=$(aws ec2 create-dhcp-options \
>  --dhcp-configuration \
>    "Key=domain-name,Values=iamyole.uk.internal" \
>    "Key=domain-name-servers,Values=AmazonProvidedDNS" \
>  --output text --query 'DhcpOptions.DhcpOptionsId')
> ```

- Create a tag for the `DHCP Option Set`
  - `aws ec2 create-tags  --resources ${DHCP_OPTION_SET_ID} --tags Key=Name,Value=${NAME}`
- Associate the DHCP Option set with the VPC

  - `aws ec2 associate-dhcp-options --dhcp-options-id ${DHCP_OPTION_SET_ID} --vpc-id ${VPC_ID}`

  ![alt text](Images/Img_08.png)

### Subnet

- Create the a Subnet for the VPC
  > ```bash
  > SUBNET_ID=$(aws ec2 create-subnet \
  > --vpc-id ${VPC_ID} \
  > --cidr-block 172.31.0.0/24 \
  > --output text --query 'Subnet.SubnetId')
  > ```
- Tag the subnet

  - `aws ec2 create-tags  --resources ${SUBNET_ID}  --tags Key=Name,Value=${NAME}`

  ![alt text](Images/Img_09.png)

### Internet Gateway (IGW)

- Create the Internet Gateway and attach it to the VPC

  > ```bash
  > INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
  > --output text --query 'InternetGateway.InternetGatewayId')
  > aws ec2 create-tags \
  > --resources ${INTERNET_GATEWAY_ID} \
  > --tags Key=Name,Value=${NAME}
  > ```

- Attach it to the VPC

  > ```bash
  > aws ec2 attach-internet-gateway \
  > --internet-gateway-id ${INTERNET_GATEWAY_ID} \
  > --vpc-id ${VPC_ID}
  > ```

  ![alt text](Images/Img_10.png)

### Route tables

- Create route tables, associate the route table to subnet, and create a route to allow external traffic to the Internet through the Internet Gateway.

  > ```bash
  > ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  > --vpc-id ${VPC_ID} \
  > --output text --query 'RouteTable.RouteTableId')
  > aws ec2 create-tags \
  > --resources ${ROUTE_TABLE_ID} \
  > --tags Key=Name,Value=${NAME}
  > aws ec2 associate-route-table \
  > --route-table-id ${ROUTE_TABLE_ID} \
  > --subnet-id ${SUBNET_ID}
  > aws ec2 create-route \
  > --route-table-id ${ROUTE_TABLE_ID} \
  > --destination-cidr-block 0.0.0.0/0 \
  > --gateway-id ${INTERNET_GATEWAY_ID}
  > ```

  ![alt text](Images/Img_11.png)

### Creating the Security Groups

- Configure security groups

  > ```bash
  > # Create the security group and store its ID in a variable
  > SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  > --group-name ${NAME} \
  > --description "Kubernetes cluster security group" \
  > --vpc-id ${VPC_ID} \
  > --output text --query 'GroupId')
  >
  > # Create the NAME tag for the security group
  > aws ec2 create-tags \
  > --resources ${SECURITY_GROUP_ID} \
  > --tags Key=Name,Value=${NAME}
  >
  > # Create Inbound traffic for all communication within the subnet to connect on ports used by the master node(s)
  > aws ec2 authorize-security-group-ingress \
  > --group-id ${SECURITY_GROUP_ID} \
  > --ip-permissions IpProtocol=tcp,FromPort=2379,ToPort=2380,IpRanges='[{CidrIp=172.31.0.0/24}]'
  >
  > # Create Inbound traffic for all communication within the subnet to connect on ports used by the worker nodes
  > aws ec2 authorize-security-group-ingress \
  > --group-id ${SECURITY_GROUP_ID} \
  > --ip-permissions IpProtocol=tcp,FromPort=30000,ToPort=32767,IpRanges='[{CidrIp=172.31.0.0/24}]'
  >
  > # Create inbound traffic to allow connections to the Kubernetes API Server listening on port 6443
  > aws ec2 authorize-security-group-ingress \
  > --group-id ${SECURITY_GROUP_ID} \
  > --protocol tcp \
  > --port 6443 \
  > --cidr 0.0.0.0/0
  >
  > # Create Inbound traffic for SSH from anywhere (Do not do this in production. Limit access ONLY to IPs or CIDR that MUST connect)
  > aws ec2 authorize-security-group-ingress \
  > --group-id ${SECURITY_GROUP_ID} \
  > --protocol tcp \
  > --port 22 \
  > --cidr 0.0.0.0/0
  >
  > # Create ICMP ingress for all types
  > aws ec2 authorize-security-group-ingress \
  > --group-id ${SECURITY_GROUP_ID} \
  > --protocol icmp \
  > --port -1 \
  > --cidr 0.0.0.0/0
  > ```

  ![alt text](Images/Img_12.png)

### Network Load Balancer

- Create a network Load balancer

  > ```bash
  > LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
  > --name ${NAME} \
  > --subnets ${SUBNET_ID} \
  > --scheme internet-facing \
  > --type network \
  > --output text --query 'LoadBalancers[].LoadBalancerArn')
  > ```

  ![alt text](Images/Img_13.png)

### Tagret Group

- Create a target group
  > ```bash
  > TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  > --name ${NAME} \
  > --protocol TCP \
  > --port 6443 \
  > --vpc-id ${VPC_ID} \
  > --target-type ip \
  > --output text --query 'TargetGroups[].TargetGroupArn')
  > ```
- Register targets: We haven't provisioned the nodes so we will be using dummy ip address as the targets for now
  - `aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=172.31.0.1{0,1,2}`
- Create a listener to listen for requests and forward to the target nodes on TCP port 6443. TCP port 6443 is typically associated with the Kubernetes API server

  > ```bash
  > aws elbv2 create-listener \
  > --load-balancer-arn ${LOAD_BALANCER_ARN} \
  > --protocol TCP \
  > --port 6443 \
  > --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} \
  > --output text --query 'Listeners[].ListenerArn'
  > ```

  ![alt text](Images/Img_14.png)

### K8s Public Address

- Get the DNS Name for the network load balancer and store it in a variable called `KUBERNETES_PUBLIC_ADDRESS`

  > ```bash
  > KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  >       --load-balancer-arns ${LOAD_BALANCER_ARN} \
  >       --output text --query 'LoadBalancers[].DNSName')
  > ```

  ![alt text](Images/Img_16.png)

## Create The Compute Resources

- Get an image to create EC2 instances

  > ```bash
  > IMAGE_ID=$(aws ec2 describe-images --owners 099720109477 \
  >       --filters \
  >       'Name=root-device-type,Values=ebs' \
  >       'Name=architecture,Values=x86_64' \
  >       'Name=name,Values=ubuntu-pro-server/images/hvm-ssd/ubuntu-xenial-16.04-amd64-pro-server-20221202' \
  > | jq -r '.Images|sort_by(.Name)[-1]|.ImageId')
  > ```

  Let's breakdown the code above. The script above obtains the latest AMI for Ubuntu, and store the value in a variable called `IMAGE_ID`. This piece of code `| jq -r '.Images|sort_by(.Name)[-1]|.ImageId':` pipes the output of the aws ec2 describe-images command to `jq`. The `jq`, a command-line JSON processor parses and manipulates the output of the aws describe-image command to obtain the specific AMI.

  ![alt text](Images/Img_17.png)

- Create SSH Key-Pair
  > ```bash
  > mkdir -p ssh
  >
  > aws ec2 create-key-pair \
  >    --key-name ${NAME} \
  >    --output text --query 'KeyMaterial' \
  >    >ssh/${NAME}.id_rsa
  > chmod 400 ssh/${NAME}.id_rsa
  > ```

### EC2 Instances for Controle Plane (Master Nodes)

- Create 3 Master nodes: Note – Using t2.micro instead of t2.small as t2.micro is covered by AWS free tier
  > ```bash
  > for i in 0 1 2; do
  >   instance_id=$(aws ec2 run-instances \
  >       --associate-public-ip-address \
  >       --image-id ${IMAGE_ID} \
  >       --count 1 \
  >       --key-name ${NAME} \
  >       --security-group-ids ${SECURITY_GROUP_ID} \
  >       --instance-type t2.micro \
  >       --private-ip-address 172.31.0.1${i} \
  >       --user-data "name=master-${i}" \
  >       --subnet-id ${SUBNET_ID} \
  >       --output text --query 'Instances[].InstanceId')
  >   aws ec2 modify-instance-attribute \
  >       --instance-id ${instance_id} \
  >       --no-source-dest-check
  >   aws ec2 create-tags \
  >       --resources ${instance_id} \
  >       --tags "Key=Name,Value=${NAME}-master-${i}"
  > done
  > ```

### EC2 Instances for Worker Nodes

- Create 3 worker nodes:

  > ```bash
  > for i in 0 1 2; do
  >   instance_id=$(aws ec2 run-instances \
  >       --associate-public-ip-address \
  >       --image-id ${IMAGE_ID} \
  >       --count 1 \
  >       --key-name ${NAME} \
  >       --security-group-ids ${SECURITY_GROUP_ID} \
  >       --instance-type t2.micro \
  >       --private-ip-address 172.31.0.2${i} \
  >       --user-data "name=worker-${i}|pod-cidr=172.20.${i}.0/24" \
  >       --subnet-id ${SUBNET_ID} \
  >       --output text --query 'Instances[].InstanceId')
  >   aws ec2 modify-instance-attribute \
  >       --instance-id ${instance_id} \
  >       --no-source-dest-check
  >   aws ec2 create-tags \
  >       --resources ${instance_id} \
  >       --tags "Key=Name,Value=${NAME}-worker-${i}"
  > done
  > ```

  ![alt text](Images/Img_18.png)
  From the screenshot above, we can see we have three(3) Master nodes and three(3) worker nodes running.

  ### Recap

  So far, we've setup the lab environment by provisioning an EC2 Instance. We then installed AWS CLI to provision the servers that the k8s cluster would run on as as well installed cfssl and cfssljson utilities to configure the security settings for the cluster. For the infrastructure, the following has been created with aws cli: - VPC - Subnet - Internet Gateway - Routes and Route Tables associated with the subnet - Network Load balancer - Target groups - Security groups - Security Key - 6 EC2 Instances (3 for the control node and 3 for the worker nodes)

Now let's start configuring the Kubernetes of the infrastructure.
