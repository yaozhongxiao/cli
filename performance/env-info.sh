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
###########################################################################
#           shell script for development environment information          #

# cpu info
# cpu_num=`cat /proc/cpuinfo | grep 'physical id'|sort|uniq|wc -l`
# logical cpu
cpu_num=`cat /proc/cpuinfo|grep 'processor'|sort|uniq|wc -l`
echo "cpu num:$cpu_num"

# total memory
memory_total=`free -h |grep 'Mem'|awk '{print $2}'`
echo  "memory total : ${memory_total}M"

# free memory
memory_free=`free -m|grep 'Mem'|awk '{print $4}'`
echo  "memory free : ${memory_free}M"

# disk size
disk_size=`df -h / | awk '{print $2}'|grep -E '[0-9]'`
echo "disk size : $disk_size"

# address size
linux_bit=`uname -i`
if (($linux_bit == 'x86_64'));then
    system_bit=64
else
    system_bit=32
fi
echo "system bit : $system_bit"

# ip address
ip=`ifconfig| grep -A 1 'eth0'|grep 'inet'|awk -F ':' '{print $2}'|awk '{print $1}'`
echo "ip : $ip"
