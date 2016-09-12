#!/bin/bash
# This file downloads the MIPLIB benchmark set and runs it using Gurobi

# Download and extract MIPLIB
wget http://miplib.zib.de/download/miplib2010-1.1.2-benchmark.tgz
tar -xvf miplib2010-1.1.2-benchmark.tgz
cd miplib2010-1.1.2

# Run the benchmark
make checker
ln -s /usr/bin/gurobi_cl ./bin/gurobi
make SOLVER=gurobi test

# Create a results file 'out.csv' with a single data row
# First entry of the row is the EC2 instance type
# Second entry of the row is base64 of the MIPLIB results file
echo 'inst_type,results' > ../out.csv
printf '%s\n' `ec2metadata --instance-type` `base64 results/benchmark.gurobi.res` | paste -sd ',' >> ../out.csv

