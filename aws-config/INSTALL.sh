#!/bin/bash
# INSTALL.sh
# Install the dependencies required to run MIPLIB on Gurobi-Ubuntu EC2 instance

# Args:
# $1: iteration number

# Exit on any incomplete command
set -e

###############################################################################
### APT--GET-CONFIG

# Nothing to do here

###############################################################################
### APT-GET-EVERYTHING

sudo apt-get update --yes > progress_B_1_$1.txt 2>&1

# Base things
sudo apt-get -y --force-yes install git python-pip python-paramiko > progress_B_2_$1.txt 2>&1

# MIPLIB things
sudo apt-get -y --force-yes install make gcc g++ libgmp3-dev zlib1g-dev cloud-utils > progress_B_3_$1.txt 2>&1

###############################################################################
### LANGUAGE PACKAGE CONFIG

# Add base packages
sudo pip install boto > progress_C_1_$1.txt 2>&1

###############################################################################
### CHECK EVERYTHING IS WORKING

# Nothing to do here

###############################################################################
### DONE

touch READY
