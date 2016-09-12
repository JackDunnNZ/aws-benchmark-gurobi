# Benchmarking Gurobi on AWS using MIPLIB

This repository contains the configuration code for running the [MIPLIB](http://miplib.zib.de/) test suite of problems using [Gurobi](http://www.gurobi.com/) on different [AWS EC2 instance types](https://aws.amazon.com/ec2/instance-types/) in order to evaluate relative performance of instance types against their costs.

It depends on the [aws-runner](https://github.com/JackDunnNZ/aws-runner) to dispatch the jobs to AWS.

## Running on AWS

From the `aws-runner` directory, run

```
python dispatcher.py miplib <aws-bench-path>/aws-config/jobdetails.csv <aws-bench-path>/aws-config/INSTALL.sh <aws-bench-path>/aws-config/remote/ out.csv --create --dispatch --verbose
```

where `<aws-bench-path>` is the path to this folder.

## Getting results

From `aws-runner` directory, run

```
python get_s3_files.py miplib <aws-bench-path>/results/raw/
```

## Analysis of output

From the `analysis` folder, run

```
julia process_results.jl
```
