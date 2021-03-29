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

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
sed -i "/cli config begin/,/cli config end./ d" ~/.bashrc
echo '#-------------------  cli config begin ----------------#' >> ~/.bashrc
echo "CLI_ROOT=${SCRIPT_DIR}" >> ~/.bashrc
echo 'PATH=${CLI_ROOT}:${CLI_ROOT}/compiler:${CLI_ROOT}/performance:${CLI_ROOT}/spec:${CLI_ROOT}/r2:${CLI_ROOT}/rpc:${CLI_ROOT}/git:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/armie:${PATH}' >> ~/.bashrc
echo '#-------------------  cli config end ------------------#' >> ~/.bashrc

echo "install complete ! ..."
