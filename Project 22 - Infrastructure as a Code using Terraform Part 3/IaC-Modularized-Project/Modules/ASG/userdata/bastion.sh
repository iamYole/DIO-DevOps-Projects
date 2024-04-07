#!/bin/bash
# Update package lists and install required packages
yum update -y

# Install Git and Ansible
yum install -y git ansible-core python ntp net-tools vim wget telnet chrony

# Start and enable the NTP service
systemctl start chronyd
systemctl enable chronyd