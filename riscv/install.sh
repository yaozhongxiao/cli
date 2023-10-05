#!/usr/bin/env bash
#
# Copyright 2023 WorkGroup Participants. All rights reserved
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
script_dir="$(cd "$(dirname "$0")"; pwd -P)"
source ${script_dir}/../env.sh

config_file=~/.bashrc
$xsed "/riscv-cli config begin/,/riscv-cli config end./ d" $config_file
echo '#-------------------  riscv-cli config begin ----------------#' >> $config_file
echo "RISCV_CLI_ROOT=${script_dir}" >> $config_file
echo 'PATH=${RISCV_CLI_ROOT}:${PATH}' >> $config_file
echo '#-------------------  riscv-cli config end ------------------#' >> $config_file

echo "riscv install complete ! ..."
