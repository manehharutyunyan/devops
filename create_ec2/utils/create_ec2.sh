#!/bin/bash

source create_vpc.sh

# splits string to list by ":"
function split_string_to_list() {
  local IFS=':'    
  read -ra parts <<< "$1"    
  echo "${parts[@]}"    
}

# get security groups
function get_sg_list() {
	ports_string=$1

	# split the ports
	local ports_list=$(split_string_to_list "$ports_string")
	echo "ports are splited"
	echo "$ports_list"

	# the list of security groups
	local sg_list=()

	# create sg for each port and store it into a list
	for port in $ports_list
	do
		local sg=$(create_sg "$vpc_id" "$port")
		sg_list+=("$sg")
	done 

	# return sgs list
	echo "${sg_list[@]}"
}

# creates an ec2 instance in a vpc
create_ec2() {
	local subnet_id=$1
	local ports_string=$2

	# create the vpc
	create_vpc

	# get list of security groups
	local sg_list=$(get_sg_list "$ports_string")
	echo "list of security groups"
	echo "$sg_list"

	# create ec2 instance in the vpc
	aws ec2 run-instances \
		--image-id ami-00eeedc4036573771 \
		--count 1 \
		--instance-type t2.micro \
		--key-name MyKeyPair \
		--subnet-id $subnet_id \
		--security-group-ids $sg_list \
		&& echo "created an ec2 instance" || exit 1
}
