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
R2_REPO="git@github.com:radareorg/radare2.git"

WORK_DIR=`pwd`
R2_ROOT=${WORK_DIR}
R2_PRO=radare2
ACTION_FORCE=false

function usage() {
    cat << EOF
    Usage: $0 [options]
    Options:
        -h|--help         This Message.
        --root            Set The LLVM Compiler Root Directory.
        -f|--force        Force Run.
        --without-pull    disable the pull from remote repo(default is pull)
EOF
}

ARGS=()
function options_parse() {
    while test $# -gt 0; do
        case "$1" in
            --root)
                shift
                if [ x"$1" != x"-*" ];then
                    R2_ROOT=$1
                fi
                ;;
            -f|--force)
                ACTION_FORCE=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                ARGS+=($1)
                ;;
        esac
        shift
    done
}

# options parsing
echo $0 $@
options_parse $@

R2_SRC=${R2_ROOT}/${R2_PRO}
R2_RELEASE=${R2_ROOT}/${R2_PRO}-release
if [ -d ${R2_SRC} ];then
    read -p "${R2_SRC} has exists, confirm to continue [y/n]" options
    if [ x$options != x'y' ];then
        exit
    fi
else
    mkdir -p ${R2_SRC}
    git clone ${R2_REPO} ${R2_SRC} --recursive
fi

if [ -d ${R2_RELEASE} ];then
    rm -rf ${R2_RELEASE}
fi
# mkdir -p ${R2_RELEASE}

set -x
cd ${R2_SRC}
cp ${SCRIPT_DIR}/install-commit.diff install-commit.diff
git apply install-commit.diff
sh sys/user.sh --without-pull ${ARGS[@]}
