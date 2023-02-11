#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

s3bucket="$1"
if [[ -z ${s3bucket} ]]; then
    echo "ERROR: Please provide the s3 bucket name"
    exit 1
fi
echo "copying my_spark_job.py file from s3 to /home/hadoop"
aws s3 cp s3://${s3bucket}/mytemplates/emrcluster-iac/python/my_spark_job.py /home/hadoop/my_spark_job.py
echo "Spark Submit PySpark Code"
spark-submit \
    --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
    --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
    /home/hadoop/my_spark_job.py \
        --s3_bucket "${s3bucket}" 