#!/bin/bash

# Update package lists
sudo apt update

# Install required packages
sudo apt install -y python3 ntp net-tools vim wget git htop php

# Cloning the tooling site
git clone https://github.com/darey-io/tooling.git

# Move the Web Files to the html directory
cd tooling/html
cp -R  * /var/www/html