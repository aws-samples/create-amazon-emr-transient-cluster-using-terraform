#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

while [ $# -gt 0 ]; do
  case "$1" in
    --s3bucket|--s3bucket=|-b)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      s3bucket="${1#*=}"
      ;;
    --subnetid|--subnetid=|-s)
      if [[ "$1" != *=* ]]; then shift; fi
      subnetid="${1#*=}"
      ;;
    --rootvolumesize|--rootvolumesize=|-r)
      if [[ "$1" != *=* ]]; then shift; fi
      rootvolumesize="${1#*=}"
      ;;
    --numcoreinstances|--numcoreinstances=|-n)
      if [[ "$1" != *=* ]]; then shift; fi
      numcoreinstances="${1#*=}"
      ;;
    --help|-h)
      printf "Expecited args --s3bucket or -s, --subnetid or -s,  --rootvolumesize or -r, --numcoreinstances or -n" # Flag argument
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done
echo "DEBUG: Input Arguments"
echo "DEBUG: s3bucket = ${s3bucket}"
echo "DEBUG: subnetid = ${subnetid}"
echo "DEBUG: rootvolumesize = ${rootvolumesize}"
echo "DEBUG: numcoreinstances = ${numcoreinstances}"
if [ -z ${s3bucket} ] || [ -z ${subnetid} ]; then
    echo "ERROR: Please provide the s3bucket and subnetid as inputs and  arg. E.g. 'sh common_dbgen_script.sh --s3bucket my-s3-bucket --subnetid abcd1234' OR  'sh common_dbgen_script.sh -b my-s3-bucket -s abcd1234'"
    exit 1
fi
if [[ -z ${rootvolumesize} ]]; then
    echo "DEBUG: Defaulting root volume size to 64 GB"
    rootvolumesize=64
fi
if [[ -z ${numcoreinstances} ]]; then
    echo "DEBUG: Defaulting number of core instances to 1"
    numcoreinstances=1
fi
echo "DEBUG: aws s3 cp ../scripts s3://${s3bucket}/mytemplates/emrcluster-iac/scripts --recursive"
aws s3 cp ../scripts s3://${s3bucket}/mytemplates/emrcluster-iac/scripts --recursive
echo "DEBUG: aws s3 cp ../python s3://${s3bucket}/mytemplates/emrcluster-iac/python --recursive"
aws s3 cp ../python s3://${s3bucket}/mytemplates/emrcluster-iac/python --recursive
echo "DEBUG: Running terraform init"
terraform init
echo "DEBUG: Running terraform fmt"
terraform fmt
echo "DEBUG: Running terraform validate"
terraform validate
echo "DEBUG: Running terraform workspace new mytfworkspace"
terraform workspace new mytfworkspace
echo "DEBUG: Running terraform apply"
terraform apply -auto-approve \
    -var "s3bucket=${s3bucket}" \
    -var "subnetid=${subnetid}" \
    -var "rootvolumesize=${rootvolumesize}" \
    -var "numcoreinstances=${numcoreinstances}"
    -auto-approve
echo "terraform init"
terraform show