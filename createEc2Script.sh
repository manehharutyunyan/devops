#!/bin/bash

# create a VPC with 10.0.0.0/16 CIDR block
vpc_id=`aws ec2 create-vpc \
	--cidr-block 10.0.0.0/16 \
	--query 'Vpc.VpcId' \
	--output text` \
	&& echo "VPC created" || exit 1

# enable DNS hostname of a VPC
(aws ec2 modify-vpc-attribute \
	--vpc-id $vpc_id \
	--enable-dns-hostnames "{\"Value\":true}") \
	&& echo "DNS hostname enabled"

# create an Internet Gateway
igw_id=`aws ec2 create-internet-gateway \
	--query 'InternetGateway.InternetGatewayId' \
	--output text` \
	&& echo "Internet Gateway created" || exit 1

# attach the gateway to VPC
(aws ec2 attach-internet-gateway \
    --internet-gateway-id $igw_id \
    --vpc-id $vpc_id) \
	&& echo "attached the gateway to VPC" || exit 1
	
# create a route table
rt_id=`aws ec2 create-route-table \
	--vpc-id $vpc_id \
	--query 'RouteTable.RouteTableId' \
	--output text` \
	&& echo "Route Table created" || exit 1

# add Route to Route Table
(aws ec2 create-route \
	--route-table-id $rt_id \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $igw_id) \
	&& echo "added Route to Route Table" || exit 1

# create a subnet with an IPv4 CIDR block
subnet_id=`aws ec2 create-subnet \
    --vpc-id $vpc_id \
    --cidr-block 10.0.0.0/24 \
	--availability-zone us-east-2a \
	--query 'Subnet.SubnetId' \
	--output text` \
	&& echo "subnet created" || exit 1
	
# enable auto-assign public IPV4 addr of a subnet
(aws ec2 modify-subnet-attribute \
	--subnet-id $subnet_id \
	--map-public-ip-on-launch) \
	&& echo "enabled auto-assign public IPV4 addr of a subnet" || exit 1

# associate a route table with a subnet
(aws ec2 associate-route-table \
	--route-table-id $rt_id \
	--subnet-id $subnet_id) \
	&& echo "associated a route table with a subnet" || exit 1
	
# create security group
sg_id1=`aws ec2 create-security-group \
	--group-name Ec2SecurityGroup \
	--description "My security group" \
	--vpc-id $vpc_id \
	--query 'GroupId' \
	--output text` \
	&& echo "Security Group created" || exit 1
	
# open the SSH port(22) in the ingress rules
(aws ec2 authorize-security-group-ingress \
	--group-id $sg_id1 \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0) \
	&& echo "opened the SSH port" || exit 1
	
# create security group
sg_id2=`aws ec2 create-security-group \
        --group-name Ec2SecurityGroup \
        --description "My security group" \
        --vpc-id $vpc_id \
        --query 'GroupId' \
        --output text` \
        && echo "Security Group created" || exit 1

# open the SSH port(80) in the ingress rules
(aws ec2 authorize-security-group-ingress \
        --group-id $sg_id2 \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0) \
        && echo "opened the SSH port" || exit 1

# create ec2 instance in our vpc
(aws ec2 run-instances \
	--image-id ami-00eeedc4036573771 \
	--count 1 \
	--instance-type t2.micro \
	--key-name MyKeyPair \
	--subnet-id $subnet_id \
	--security-group-ids ($sg_id1 $sg_id2) ) \
	&& echo "created an ec2 instance" || exit 1
