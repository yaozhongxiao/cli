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

DOWNLOAD_URL="https://armkeil.blob.core.windows.net/developer/Files/downloads/hpc/arm-instruction-emulator/20-1/ARM-Instruction-Emulator_20.1_AArch64_RHEL_7_aarch64.tar.gz"
ARMIE_VERSION="armie-aarch64-20.1"
INSTALL_PATH=${ROOT_DIR}/armie
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
ARMIE_ROOT=${INSTALL_PATH}/${ARMIE_VERSION}

echo "script-root      : ${SCRIPT_DIR}"
echo "download-url     : ${DOWNLOAD_URL}"
echo "armie-root       : ${ARMIE_ROOT}"
echo "current dir      : `pwd`"

set -x
function armie_install() {
    local download_url=$1
    local install_root=$2
    local download_path=${install_root}/download
    local install_path=${install_root}
    local armie_tar=${download_path}/${ARMIE_VERSION}.tar.gz
    if [ ! -f ${armie_tar} ];then
        mkdir -p ${download_path}
        command -v proxychains4 >/dev/null 2>&1 && {
            proxychains4 wget ${download_url} -O ${armie_tar}
        } || {
            wget ${download_url} -O ${armie_tar}
        }
    fi
    cd ${download_path}
    tar -xzvf ${armie_tar} -C ${download_path} --strip-components 1
    local rmp_install_cmd=arm-instruction-emulator-20.1_Generic-AArch64_RHEL-7_aarch64-linux-rpm.sh
    sh ${rmp_install_cmd} --force --accept -i ${install_path}
    # remove the download tmp file
    # rm -rf ${install_path}/download
}
armie_install ${DOWNLOAD_URL} ${ARMIE_ROOT}

command -v proxychains4 >/dev/null 2>&1 || {
    sudo yum install -y environment-modules
}
ARMIE_MODULE=Generic-AArch64/RHEL/7/arm-instruction-emulator/20.1
# set the environment
sed -i "/armie begin/,/armie end./ d" ~/.bashrc
echo "#-------------------  armie begin ----------------#" >> ~/.bashrc
echo "ARMIE_ROOT=${ARMIE_ROOT}" >> ~/.bashrc
echo 'export MODULEPATH=$MODULEPATH:${ARMIE_ROOT}/modulefiles' >> ~/.bashrc
echo "module load ${ARMIE_MODULE}" >> ~/.bashrc
echo '#-------------------  armie end ------------------#' >> ~/.bashrc

echo "armie install complete ..."
echo "use <source ~/.bashrc> to enable modules"
