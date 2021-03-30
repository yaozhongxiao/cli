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
ROOT_DIR=`pwd`

function usage() {
    cat << EOF
    Usage: $0 [options]
    Options:
    -h|--help             This Message.
    -f|--force            Force Install.
    --dowload-url url     Download From Url(default is makefile)
    --install     path    Install To The Path
EOF
}

DOWNLOAD_URL="https://download.qemu.org/qemu-6.0.0-rc0.tar.xz"
QEMU_VERSION="qemu-6.0.0"
INSTALL_PATH=${ROOT_DIR}/qemu
function options_parse() {
    while test $# -gt 0; do
        case "$1" in
            --dowload-url)
              shift
              if [ x"$1" != x"-*" ];then
                DOWNLOAD_URL=$1
              fi
              ;;
            --install)
              shift
              if [ x"$1" != x"-*" ];then
                INSTALL_PATH=$1
              fi
              ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
            echo "Unknown option \"$1\"." >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# parse cli options
echo $0 $@
options_parse $@
QEMU_ROOT=${INSTALL_PATH}/${QEMU_VERSION}

echo "script-root      : ${SCRIPT_DIR}"
echo "download-url     : ${DOWNLOAD_URL}"
echo "qemu-root        : ${QEMU_ROOT}"
echo "current dir      : `pwd`"

set -x
function qemu_install() {
    local download_url=$1
    local install_root=$2
    local download_path=${install_root}/download
    local install_path=${install_root}
    local qemu_tar=${download_path}/${QEMU_VERSION}.tar.xz
    if [ ! -f ${qemu_tar} ];then
        mkdir -p ${download_path}
        command -v proxychains4 >/dev/null 2>&1 && {
            proxychains4 wget ${download_url} -O ${qemu_tar}
        } || {
            wget ${download_url} -O ${qemu_tar}
        }
    fi
    cd ${download_path}
    tar xvJf ${qemu_tar} -C ${download_path} --strip-components 1
    ./configure --target-list=aarch64-linux-user --prefix=${install_root}
    make -j8 && make install
    # remove the download tmp file
    # rm -rf ${install_path}/download
}
qemu_install ${DOWNLOAD_URL} ${QEMU_ROOT}

# set the environment
sed -i "/qemu begin/,/qemu end./ d" ~/.bashrc
echo "#-------------------  qemu begin ----------------#" >> ~/.bashrc
echo "QEMU_ROOT=${QEMU_ROOT}" >> ~/.bashrc
echo 'export PATH=${PATH}:${QEMU_ROOT}/bin' >> ~/.bashrc
echo '#-------------------  qemu end ------------------#' >> ~/.bashrc

echo "qemu install complete ..."
echo "use <source ~/.bashrc> to enable modules"
