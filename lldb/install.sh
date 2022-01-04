#!/usr/bin/env bash
#
# Copyright 2021 WorkGroup Participants. All rights reserved
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

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
source ${SCRIPT_DIR}/../env.sh
HOME_DIR=~

if [ -f ${HOME_DIR}/.lldbinit ];then
  rm -rf ${HOME_DIR}/.lldbinit
fi
cp -r ${SCRIPT_DIR}/.lldbinit ${HOME_DIR}/.lldbinit

if [ -d ${HOME_DIR}/.chisel ];then
  rm -rf ${HOME_DIR}/.chisel
fi
cp -rf ${SCRIPT_DIR}/.chisel ${HOME_DIR}/.chisel


#$xsed "/xcode config begin/,/xcode config end./ d" ~/.bashrc
#echo '#-------------------  xcode config begin ----------------#' >> ~/.bashrc
#echo '#-------------------  xcode config end ------------------#' >> ~/.bashrc

