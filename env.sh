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

UNAME="$(uname | tr "[:upper:]" "[:lower:]")"

OS_TYPE='unknown' # ["mac", "linux"]
OS_DIST=${UNAME}  # ["ubuntu", "centos", "darwin"]
if [ "${UNAME}" == "darwin" ];then
   OS_TYPE='mac'
elif [ "$(expr substr ${UNAME} 1 5)" == "linux" ];then
   OS_TYPE='linux'
   # If available, use LSB to identify distribution
   if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
      OS_DIST=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
   # Otherwise, use release info file
   else
      OS_DIST=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
   fi
    OS_DIST=$(echo ${OS_DIST} | tr [:upper:] [:lower:])
   if [ -z "OS_DIST" ];then
     OS_DIST=${UNAME}
   fi
else
   echo "please check the os type, because it's undefined yet!"
fi


MARCH="unknown"
case $(uname -m) in
    i386)   MARCH="386" ;;
    i686)   MARCH="386" ;;
    x86_64) MARCH="amd64" ;;
    arm64)  MARCH="arm64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && MARCH="arm64" || MARCH="arm" ;;
    *) echo "please check the march, because it's undefined yet!" ;;
esac

APT="apt-get" # advanced package tool
case "${OS_DIST}" in
  ubuntu)
    APT="apt-get"
    ;;
  centos)
    APT="yum"
    ;;
  *)
    echo "please check os distribution, because it's undefined yet!"
    ;;
esac

xsed="sed -i"
if [ x"${OS_TYPE}" == x"mac" ];then
  xsed="sed -i ''"
fi
