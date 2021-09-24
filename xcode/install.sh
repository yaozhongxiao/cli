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
source ${SCRIPT_DIR}/../env.sh
SimApp='/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'
PodSrc='/Library/Ruby/Gems/2.6.0/gems/cocoapods-1.8.4/lib/cocoapods'

$xsed "/xcode config begin/,/xcode config end./ d" ~/.bashrc
echo '#-------------------  xcode config begin ----------------#' >> ~/.bashrc
echo 'alias simopen="open -a Simulator"' >> ~/.bashrc
echo 'alias simctl="xcrun simctl"' >> ~/.bashrc
echo 'alias xccov="xcrun xccov"' >> ~/.bashrc
echo "PodSrc=${PodSrc}" >> ~/.bashrc
echo 'alias podsrc="echo ${PodSrc}"' >> ~/.bashrc
echo '#-------------------  xcode config end ------------------#' >> ~/.bashrc

