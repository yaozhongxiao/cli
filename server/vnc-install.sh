#!/usr/bin/env bash
#
# Copyright 2024 WorkGroup Participants. All rights reserved
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
script_dir="$(cd "$(dirname "$0")"; pwd -P)"
# source ${script_dir}/../env.sh

xstartup_bash=~/.vnc/xstartup
function usage() {
    cat <<EOF
    Usage: $0 [options] ;
    Options:
    -h|--help         This message.
EOF
}

sudo apt update
# install Xfce desk top environment
sudo apt install xfce4 xfce4-goodies
# install TightVNC vncserver
sudo apt install tightvncserver

[ ! -f ${xstartup_bash} ] && mkdir -p $(dirname ${xstartup_bash})
cat <<EOF > ${xstartup_bash}
#!/bin/sh
xrdb ~/.Xresources
startxfce4 &
EOF
sudo chmod +x ${xstartup_bash}

# run vncserver to config vncserver
vncserver

# echo "refer to https://support.huaweicloud.com/bestpractice-ecs/zh-cn_topic_0168615364.html"
echo "run 'vncserver -localhost yes|no' to start vncserver!"