# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

data "template_file" "configuration" {
  template = file("${path.module}/../config/cluster-config-glue-catalog.json")
}

data "aws_caller_identity" "current" {}

variable "EMRClusterInstanceProfileRoleName" {
  description = "Name of the IAM Role EMRClusterInstanceProfileRole"
  type        = string
  default     = "EMRClusterInstanceProfileRole"
}

variable "EMRClusterServiceRoleName" {
  description = "Name of the IAM Role EMRClusterServiceRole"
  type        = string
  default     = "EMRClusterServiceRole"
}

variable "subnetid" {
  description = "subnetid"
  type        = string
  default     = ""
}

variable "s3bucket" {
  description = "s3bucket"
  type        = string
  default     = ""
}

variable "rootvolumesize" {
  description = "rootvolumesize"
  type        = string
  default     = "20"
}

variable "numcoreinstances" {
  description = "numcoreinstances"
  type        = string
  default     = "1"
}

output "EMRClusterInstanceProfileRoleOut" {
  description = "Name of the IAM Role EMRClusterInstanceProfileRole"
  value       = aws_iam_role.EMRClusterInstanceProfileRole.arn
}

output "EMRClusterServiceRoleOut" {
  description = "Name of the IAM Role EMRClusterServiceRole"
  value       = aws_iam_role.EMRClusterServiceRole.arn
}

resource "aws_iam_role" "EMRClusterServiceRole" {
  name               = "EMRClusterServiceRole-${random_string.random.result}"
  assume_role_policy = <<EOF
    {
      "Statement": [
        {
          "Action": [
            "sts:AssumeRole"
          ],
          "Effect": "Allow",
          "Principal": {
            "Service": "elasticmapreduce.amazonaws.com"
          }
        }
      ]
    }
  EOF
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
  ]

  tags = {
    env     = "dev",
    project = "myemrproject"
  }
}

resource "aws_iam_role" "EMRClusterInstanceProfileRole" {
  name               = "EMRClusterInstanceProfileRole-${random_string.random.result}"
  assume_role_policy = <<EOF
    {
      "Statement": [
        {
          "Action": [
            "sts:AssumeRole"
          ],
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          }
        }
      ]
    }
  EOF
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  tags = {
    env     = "dev",
    project = "myemrproject"
  }
}

resource "aws_iam_instance_profile" "myInstanceProfile" {
  name       = "myInstanceProfile-${random_string.random.result}"
  role       = aws_iam_role.EMRClusterInstanceProfileRole.name
  depends_on = [aws_iam_role.EMRClusterInstanceProfileRole]

  tags = {
    env     = "dev",
    project = "myemrproject"
  }
}

resource "aws_emr_cluster" "myEMRCluster" {
  name                              = "myEMRCluster"
  release_label                     = "emr-6.9.0"
  applications                      = ["Ganglia", "Spark", "Hive", "Presto", "Livy", "JupyterHub", "Hue", "JupyterEnterpriseGateway"]
  log_uri                           = "s3n://${var.s3bucket}/myemrclusterlogs/"
  termination_protection            = false
  keep_job_flow_alive_when_no_steps = false
  ebs_root_volume_size              = max(ceil(var.rootvolumesize), 10)
  step_concurrency_level            = 10
  autoscaling_role                  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EMR_AutoScaling_DefaultRole"

  auto_termination_policy {
    idle_timeout = 3600
  }
  bootstrap_action {
    path = "s3://${var.s3bucket}/mytemplates/emrcluster-iac/scripts/bootstrap.sh"
    name = "Run bootstrap"
  }
  step = [
    {
      name              = "SparkSubmitStep"
      action_on_failure = "CONTINUE"
      hadoop_jar_step = [{
        jar        = "command-runner.jar"
        args       = ["bash", "-c", "aws s3 cp s3://${var.s3bucket}/mytemplates/emrcluster-iac/scripts/emr_step_spark_submit.sh /home/hadoop; chmod u+x /home/hadoop/emr_step_spark_submit.sh; cd /home/hadoop; ./emr_step_spark_submit.sh ${var.s3bucket}"]
        main_class = ""
        properties = {}
      }]
    }
  ]
  service_role = aws_iam_role.EMRClusterServiceRole.arn
  depends_on = [
    aws_iam_instance_profile.myInstanceProfile,
    aws_iam_role.EMRClusterInstanceProfileRole,
    aws_iam_role.EMRClusterServiceRole
  ]
  configurations = data.template_file.configuration.rendered

  ec2_attributes {
    subnet_id        = var.subnetid
    instance_profile = aws_iam_instance_profile.myInstanceProfile.arn
  }

  master_instance_group {
    instance_type  = "m3.xlarge"
    instance_count = 1
    ebs_config {
      size = max(ceil(var.rootvolumesize), 64)
      type = "gp2"
    }
  }

  core_instance_group {
    instance_type  = "m3.xlarge"
    instance_count = var.numcoreinstances
    ebs_config {
      size = max(ceil(var.rootvolumesize), 64)
      type = "gp2"
    }
  }

  tags = {
    env     = "dev"
    project = "myemrproject"
  }
}

resource "aws_emr_managed_scaling_policy" "myManagedScalingPolicy" {
  cluster_id = aws_emr_cluster.myEMRCluster.id
  compute_limits {
    unit_type                       = "Instances"
    minimum_capacity_units          = 1
    maximum_capacity_units          = 2
    maximum_ondemand_capacity_units = 2
    maximum_core_capacity_units     = 2
  }
  depends_on = [aws_emr_cluster.myEMRCluster]
}

resource "random_string" "random" {
  length           = 6
  special          = true
  override_special = "_-"
}