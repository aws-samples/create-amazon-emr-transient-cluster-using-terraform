#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform init
echo "Selecting terraform workspace"
terraform workspace select mytfworkspace
terraform show
terraform destroy -auto-approve