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

OS_TYPE='unknown'
if [ "$(uname)" == "Darwin" ];then
   OS_TYPE='mac'
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ];then
   OS_TYPE='linux'
else
    echo "please check the os type, because it's undefined yet!"
fi


MARCH="unknown"
case $(uname -m) in
    i386)   MARCH="386" ;;
    i686)   MARCH="386" ;;
    x86_64) MARCH="amd64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && MARCH="arm64" || MARCH="arm" ;;
    *) echo "please check the march, because it's undefined yet!" ;;
esac

