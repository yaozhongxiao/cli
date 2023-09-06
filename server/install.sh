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
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
source ${SCRIPT_DIR}/../env.sh

config_file=~/.bashrc

$xsed "/server config begin/,/server config end./ d" $config_file
echo '#-------------------  server config begin ----------------#' >> $config_file
echo "PATH=\${PATH}:${SCRIPT_DIR}:${SCRIPT_DIR}/rpc" >> $config_file
echo '#-------------------  server config end ------------------#' >>$config_file

