# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import sys
import os
import argparse
from delta.tables import *
from pyspark.sql.functions import *

class MySparkApplication():

  def __init__(self, s3_bucket) -> None:
    emr_cluster_id = os.environ.get('EMR_CLUSTER_ID')
    emr_step_id = os.environ.get('EMR_STEP_ID')
    print(f"Running: Cluster ID - {emr_cluster_id}; EMR Step ID - {emr_step_id}")
    print("creating spark session")
    from pyspark.sql import SparkSession
    self.spark = SparkSession.builder \
                      .enableHiveSupport() \
                      .appName(f'SparkJob_{emr_cluster_id}_{emr_step_id}') \
                      .getOrCreate()
    print(self.spark.sparkContext)
    print("Spark App Name : "+ self.spark.sparkContext.appName)
    self.s3_bucket = s3_bucket
    self.db_name = "ext_tbls"
    self.tbl_name = "mytable"

  def write_data_to_s3(self, location):
    dataDictionary = [
        {'name':'jack','designation':'ceo'},
        {'name':'jill','designation':None},
        {'name':'andy','designation':'manager'},
        {'name':'john','designation':'developer'},
        {'name':'kim','designation':'intern'}
        ]
    df = self.spark.createDataFrame(data=dataDictionary, schema = ["name","designation"])
    df.printSchema()
    df.show(truncate=False)
    print(f"Writing delta data at {location}")
    return df.write \
        .format("parquet") \
        .mode("overwrite") \
        .option("compression", "snappy") \
        .save(location)

  def create_glue_table(self):
    location = f"s3://{self.s3_bucket}/emrdata/{self.db_name}/{self.tbl_name}"
    self.write_data_to_s3(location)
    self.spark.sql(f"""CREATE DATABASE IF NOT EXISTS {self.db_name} LOCATION 's3://{self.s3_bucket}/emrdata/{self.db_name}'""")
    self.spark.sql(f"""DROP TABLE IF EXISTS {self.db_name}.{self.tbl_name}""")
    self.spark.sql(f"""create external table IF NOT EXISTS {self.db_name}.{self.tbl_name}
      (
        name STRING,
        designation STRING
      ) 
      STORED AS PARQUET
      LOCATION '{location}'"""
    )
    print(f"Querying {self.db_name}.{self.tbl_name} glue external table")
    df=self.spark.sql(f"select * from {self.db_name}.{self.tbl_name}")
    df.show(10, truncate=False)

  def main(self):
    self.create_glue_table()

if __name__=="__main__":
  print("Starting PySpark Job")
  parser = argparse.ArgumentParser()
  parser.add_argument("--s3_bucket", type=str, help="S3 Bucket Name for reading the data and pointing the tables")
  args = parser.parse_args()
  print("args")
  print(args)
  sparkapp_obj = MySparkApplication(s3_bucket = args.s3_bucket)
  sparkapp_obj.main()
  print("Finished PySpark Job")