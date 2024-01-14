# Implementing Networking Concepts in AWS (VPC, Subnets, IG, NAT, Routing, etc

Implementing networking concepts in AWS involves setting up and configuring various AWS services to build a scalable, secure, and efficient network infrastructure. Below are some key networking concepts in AWS:

- Virtual Private Cloud (VPC),
- Subnet,
- Internet Gateway,
- Domain Name System - DNS,
- Natwork Address Transaltion (NAT), etc,

We will be create some of the items mentioned above in this project and brield mentation and explain some not mention above. Let's begin.

### Part 1 - Creating a VPC

In AWS, a Virtual Private Cloud (VPC) is a virtual network dedicated to your AWS account. It provides a logically isolated section of the AWS Cloud where you can launch AWS resources in a virtual network that you define. With a VPC, you have control over your network environment, including IP address ranges, subnets, route tables, and network gateways. AWS comes pre-configured with a default VPC for each region which can be configured.  
To View this,

- Login in to your AWS Account
- From the top left corner of the page, click on services and then search for `VPC`
  ![Alt text](Images/Img_01.png)
- Click on the VPC menu, and on the left pane, select `Your VPC` sub menu under the `Virtual private cloud menu`.
  ![Alt text](Images/Img_02.png)
  From this page, you can see the default VPC, the VPCID, and other basic settings of the VPC.

#### Creating a New VPC

- In the top right corner of the `Your VPC` sub menu, click on create VPC.
- On the `Create VPC` page, select VPC only, give your VPC a name, and type in `10.0.0.0/16` in the IPV4 CIDR, and then create the VPC.
  ![Alt text](Images/Img_03.png)
- This will create a VPC with no Subnet or Internet Gatway. From the Image below, you can see the resource map section is quite empty. After we've fully configured the VPC, we will revisit the resource Map.
  ![Alt text](Images/Img_04.png)

#### Creating the Subnets

Subnets are used to divide a larger network into smaller, more manageable segments. Each subnet can operates as an independent unit within the overall network. Subnets can also be public (allows external traffic from the Internet) as well as private (Cannont connect outside the VPC, no Internet traffic). We will be creating both private and public subnets.

- In my current AWS Region (eu-west-2), the default vpc comes with 3 subnets, 1 for each Availablity Zone.
  ![Alt text](Images/Img_05.png)
- For our `dio-vpc`, we will be creating 4 subnets, 2 private and 2 public with the details below:

  | Subnet Name   | Visibility | Availablity Zone | CIDIR Block |
  | ------------- | ---------- | ---------------- | ----------- |
  | subnet-pub-1  | Public     | eu-west-2a       | 10.0.2.0/24 |
  | subnet-pub-2  | Public     | eu-west-2b       | 10.0.4.0/24 |
  | subnet-priv-1 | Private    | eu-west-2a       | 10.0.1.0/24 |
  | subnet-priv-2 | Private    | eu-west-2b       | 10.0.3.0/24 |

  - Click on `Create Subnet` from the top right corner of the page, and then create 4 subnets using details in the table above. Ensure the subnets are created in the `dio-vpc`.  
    ![Alt text](Images/Img_06.png)

- After all 4 subnets have been created, we can see our subnets and the number of IPs in each subnets as well as the AZz in the image below.
  ![Alt text](Images/Img_07.png)

  We've sucessfully created our Subnets, and we can setup our EC2 Instance in any of these subnets. However, the `Public` subnets for now don't have access to the internet. Let's fix this.
