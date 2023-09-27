#!/bin/bash
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

set -ex

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"

WAMR_HOME="`pwd`/third_party/wamr"
WAMR_INSTALL_DIR=""
WAMR_BUILD_FORCE=false

function usage() {
  cat << EOF
  Usage: $0 [options]
  Options:
      --wamr            Set WAMR's Source Root
      --install         Set The Output Directory
      --force           Force to rebuild all
EOF
}

function options_parse() {
  while test $# -gt 0; do
      case "$1" in
        --wamr)
          shift
          WAMR_HOME=$1
          ;;
        --install)
          shift
          WAMR_INSTALL_DIR=$1
          ;;
        --force)
          WAMR_BUILD_FORCE=true
          ;;
      esac
      shift
  done
}

echo $0 $@
options_parse $@

# FIXME(set WAMR_HOME auto with platform type)
WAMR_PRODUCT_DARWIN=${WAMR_HOME}/product-mini/platforms/darwin
WAMR_PRODUCT=${WAMR_PRODUCT_DARWIN}
if [ -z $WAMR_INSTALL_DIR ];then
  WAMR_INSTALL_DIR=${WAMR_HOME}/out
fi
if [ ! -z "$WAMR_INSTALL_DIR" -a x"${WAMR_INSTALL_DIR:0:1}" != x"/" ];then
  WAMR_INSTALL_DIR="`pwd`/${WAMR_INSTALL_DIR}"
fi

if [ x"true" == x"$WAMR_BUILD_FORCE" ];then
  rm -rf ${WAMR_INSTALL_DIR}
fi

cd ${WAMR_HOME}
echo "Current Directory: `pwd`"

if [ -d build ];then
  rm -rf build
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${WAMR_INSTALL_DIR} .. && make -j$nproc
make install
