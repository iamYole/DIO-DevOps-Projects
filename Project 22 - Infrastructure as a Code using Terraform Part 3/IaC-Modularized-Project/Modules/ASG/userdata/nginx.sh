#!/bin/bash
# Update package lists and install required packages
yum update -y

# Install required packages
yum install -y python ntp net-tools vim wget telnet chrony nginx-all-modules.noarch

# Start and enable the NTP service
systemctl start chronyd
systemctl enable chronyd

# Start and enable the NGINX service
systemctl start nginx
systemctl enable nginx