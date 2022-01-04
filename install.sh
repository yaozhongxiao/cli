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
source ${SCRIPT_DIR}/env.sh

$xsed "/cli config begin/,/cli config end./ d" ~/.bashrc
echo '#-------------------  cli config begin ----------------#' >> ~/.bashrc
echo "CLI_ROOT=${SCRIPT_DIR}" >> ~/.bashrc
echo 'PATH=${CLI_ROOT}:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/compiler:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/performance:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/spec:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/r2:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/rpc:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/git:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/armie:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/gn:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/ninjatracing:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/binutil:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/cmd:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/xcode:${PATH}' >> ~/.bashrc
echo 'PATH=${CLI_ROOT}/android:${PATH}' >> ~/.bashrc
echo '#-------------------  cli config end ------------------#' >> ~/.bashrc

echo "run git/install.sh for git config"
echo "run vim/install.sh for vim config"

${SCRIPT_DIR}/compiler/install.sh
${SCRIPT_DIR}/xcode/install.sh
${SCRIPT_DIR}/android/install.sh
${SCRIPT_DIR}/docs/install.sh

echo "install complete ! ..."
