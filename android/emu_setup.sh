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
echo $0 \$user options
script_dir="$(cd "$(dirname "$0")"; pwd -P)"

option=$1
user_name=$2
# Install and Create Emulators using avdmanager and sdkmanager
# https://gist.github.com/mrk-han/66ac1a724456cadf1c93f4218c6060ae
if [ x"${option}" = x"install"];then
   sdkmanager --install "system-images;android-29;default;x86"
   avdmanager --verbose create avd --force --name "Platform_4_API_29" \
      --package "system-images;android-29;default;x86" \
      --tag "default" --abi "x86"
fi

# setup the qemu-kvm and adduser(Ubuntu)
# https://stackoverflow.com/questions/37300811/android-studio-dev-kvm-device-permission-denied

# android emulator must enable hardware acceleration
# which need to setup the qemu-kvm and adduser
# DO NOT use sudo for root account
xsudo=
if [ ! -z "${USER}" -a x"${USER}" != x"root" ];then
   xsudo=sudo
fi
$xsudo apt update -y
$xsudo apt install qemu-kvm -y
# $xsudo apt install -y libvirt-clients libvirt-daemon-system \
#             bridge-utils libguestfs-tools virtinst libosinfo-bin
if [ ! -z "${USER}" -a x"${USER}" != x"root" ];then
   $xsudo adduser ${USER} kvm
   $xsudo chown -R ${USER} /dev/kvm
   grep kvm /etc/group
fi

ls -la /dev/kvm
