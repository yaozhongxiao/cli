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

$xsed "/android-sdk config begin/,/android-sdk config end/ d" ~/.bashrc
echo '#-------------------  android-sdk config begin ----------------#' >> ~/.bashrc
echo 'export ANDROID_SDK_HOME=${ANDROID_HOME}' >> ~/.bashrc
echo 'export PATH=${ANDROID_SDK_HOME}/platform-tools:$PATH' >> ~/.bashrc
echo 'export PATH=${ANDROID_SDK_HOME}/emulator:$PATH' >> ~/.bashrc
echo 'export PATH=${ANDROID_SDK_HOME}/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
echo '# export ANDROID_AVD_HOME=~/.android/avd' >> ~/.bashrc
echo '#-------------------  android-sdk config end ------------------#' >> ~/.bashrc

