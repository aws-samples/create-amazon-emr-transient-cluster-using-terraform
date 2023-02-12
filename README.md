# Create a transient cluster in Amazon EMR for Spark Jobs using terraform

## Description

This repository contains sample terraform template to create a transient EMR cluster. The template will also submit [a pyspark job](python/my_spark_job.py) as an EMR Step. It also has a sample [bootstrap script](scripts/bootstrap.sh) which will run before when EMR cluster starts provisioning. Once the EMR Step that is running the Pyspark Job finishes, the EMR cluster will be terminated. We can add more jobs by adding more steps in the [terraform template](template/main.tf).

## Architecture Diagram

![Alt text](architecture/tpch_benchmarks_on_emr.jpg?raw=true "Architecture Diagram")

## Pre-requisite

1. A subnet (private subnet recommended)
2. An s3 bucket (to deploy the relative file and store the sample data)

### Networking VPC & Subnet

To learn more about VPCs, please refer the [user-guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html).

To learn how to create a new VPC please refer [working with VPC](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-vpcs.html#Create-VPC).

### An S3 bucket

To learn more about S3, please refer the [user-guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html).

To learn how to create a bucket, please refer the [user-guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html).

### Terraform

To learn more about Terraform, please refer [the tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code).

To learn how to install Terraform, please refer [tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

## Contents
This repository contains 
1. [An Architecture Diagram](architecture/tpch_benchmarks_on_emr.jpg) to showcase the resources that are created.
2. [A Config file](config/cluster-config-glue-catalog.json) needed for EMR cluster configuration.
3. [A Bootstrap script](scripts/bootstrap.sh) for EMR cluster.
4. [A shell script](scripts/emr_step_spark_submit.sh) for EMR Step to run spark job.
5. [A shell script](template/create-inf.sh) to deploy the terraform template.
6. [A terraform template](template/main.tf) that creates - an EMR cluster, EMR cluster Service Role, EMR cluster Instance Profile Role, Instance Profile, Managed Scaling Policy for EMR cluster

## Deployment Sequence

### Install Terraform

To learn how to install Terraform, please refer [tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli). You can skip this step if you already have Terraform.

### Login to AWS from the command line

To learn how to setup aws-cli and login to an AWS account from the commmand line please refer [the userguide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

### Start deployment
To deploy from command line, run [Deployment Script](template/create-inf.sh)

`$ sh create-inf.sh -b my-bucket -s mysubnet -r 10 -n 2`
`$ sh create-inf.sh --s3bucket my-bucket --subnetid mysubnet -r 10 -n 2`
`$ sh create-inf.sh --s3bucket my-bucket --subnetid mysubnet --rootvolumesize 5 --numcoreinstances 2`

mandatory arguments - `s3bucket`, `subnetid`
optional arguments - `rootvolumesize` (defaults 64 GB), `numcoreinstances` (defaults to 1)

####  Terraform Apply

To learn more about Terraform Apply command please refer [the documentation](https://developer.hashicorp.com/terraform/cli/commands/apply).

##### Provide variables through a file

You can also optionally provide input variables through a configuration file and then provide the variable file as an input to the apply command. 
E.g. if you have stored input variables in `testing.tfvars` file, then the apply command would be `terraform apply -var-file="testing.tfvars"`

To learn more please refer the [documentation](https://developer.hashicorp.com/terraform/language/values/variables)

#### Resource creation & hardware provisioning

Once you run the `create-inf.sh` script, you should be able to see an EMR cluster being created in the AWS account. 

Following resources will be created - 
an EMR cluster, EMR cluster Service Role, EMR cluster Instance Profile Role, Instance Profile, Managed Scaling Policy for EMR cluster

#### Submit spark job using EMR Step

The [emr_step_spark_submit.sh](scripts/emr_step_spark_submit.sh) script copies the [python script](python/my_spark_job.py) onto the EMR cluster and run submits a spark job using the `spark-submit` command. The EMR Step uses command runner to run the shell script. 

To learn more about command runner please refer [emr-commandrunner](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-commandrunner.html).

### Destroy Resources

To destroy the resource from command line, run [Destroy Infrastructure Script](template/destroy-inf.sh). This will destroy all the resources created. 

`$ sh destroy-inf.sh`

Please not that the `keep_job_flow_alive_when_no_steps` parameter in [main.tf](template/main.tf) is set to `false`, so the EMR cluster will be terminated when the EMR Step finishes. To keep the EMR cluster alive after the EMR Step executes, change this parameter to `true`.

# Security
See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

# License
This library is licensed under the MIT-0 License. See the LICENSE file.

# Repo 

https://github.com/aws-samples/create-amazon-emr-transient-cluster-using-terraform