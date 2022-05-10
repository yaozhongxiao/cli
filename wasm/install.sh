#!/usr/bin/env bash
#
# Copyright 2022 WorkGroup Participants. All rights reserved
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

config_bash=~/.bashrc
$xsed "/cli wasm begin/,/cli wasm end/d" ${config_bash}
echo '#------------------- cli wasm begin ----------------#' >> $config_bash
echo '#------------------- cli wasm end ------------------#' >> $config_bash

