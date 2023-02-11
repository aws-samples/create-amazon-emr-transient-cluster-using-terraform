#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

echo "running bootstrap"
echo "running sudo yum install make git"
sudo yum install make git -y
echo "cd home"
cd $HOME
echo "running sudo yum install gcc"
sudo yum install gcc -y
echo "finished bootstrap script"