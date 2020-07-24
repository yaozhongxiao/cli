#!/usr/bin/env bash
#
# Copyright 2020 WorkGroup Participants. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###########################################################################
#     shell script for performace analyzing setup (perf, flame graph)     # 

read -p "try to reset system configuration, Is This Ok [y/n]" grant
if [ x$grant != x'y' ];then
    exit;
fi

export PATH=.:$PATH
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
PROJECT_DIR=${SCRIPT_DIR}/..

#yum clean all
#yum makecache
yum update -y --skip-broken

# 0. setup gcc and links
OS_="linux"
if [ x${OS_} != x"linux" ];then
    echo "only support perf in linux"
fi

yum install -y perf

# try to remove the "tmp" directory
cd $SCRIPT_DIR
rm -rf tmp

echo "done ..."

