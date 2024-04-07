#!/bin/bash

# Update package lists
sudo apt update

# Install required packages
sudo apt install -y python ntp net-tools vim wget git htop php

# Install WordPress and its dependencies
sudo apt install -y wordpress