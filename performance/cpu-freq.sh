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

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
ACTION_FORCE=false

CPU_FREQ_ALL=/sys/devices/system/cpu/cpu[0-9]*/cpufreq
CPU0_FREQ=/sys/devices/system/cpu/cpu0/cpufreq
if [ ! -d "${CPU0_FREQ}" ];then
    echo "can not find ${CPU0_FREQ}"
    exit -1
fi

function usage() {
    cat << EOF
    Usage: $0 [options]
    Options:
        -h|--help      This Message.
        --show         Show cpu frequency information
        --freq         Set the cpu frequency
        --gov          Set the cpu governor
        -----------------------------------------------------------------------
        # Reference:
          - https://community.mellanox.com/s/article/how-to-set-cpu-scaling-governor-to-max-performance--scaling-governor-x
          - https://wiki.archlinux.org/index.php/CPU_frequency_scaling
          - https://software.intel.com/sites/default/files/comment/1716807/how-to-change-frequency-on-linux-pub.txt
EOF
}

OPT_FREQ=
OPT_GOVERNOR=
OPT_VERBOSE=

function show() {
  cpu_count=`cat /proc/cpuinfo | grep processor | wc -l`
  avail_gover=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`
  cur_gover=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

  scale_avail_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies`
  scale_max_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq`
  scale_min_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq`
  scale_cur_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`

  cpu_cur_freq=`sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq`
  cpu_max_freq=`sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`
  cpu_min_freq=`sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq`

  cat << EOF
     avail_governor   : ${avail_gover}
     current_governor : ${cur_gover}
     scale_avail_freq : ${scale_avail_freq}
     scale_max_freq   : ${scale_max_freq}
     scale_min_freq   : ${scale_min_freq}
     scale_cur_freq   : ${scale_cur_freq}
     cpu_max_freq     : ${cpu_max_freq}
     cpu_min_freq     : ${cpu_min_freq}
     cpu_cur_freq     : ${cpu_cur_freq}
EOF

  if [ xtrue = x$OPT_VERBOSE ];then
    echo ------------- ${cpu_count} cpus -------------------
    cat ${CPU_FREQ_ALL}/scaling_governor
    cat /proc/cpuinfo |grep -i mhz
  fi
}

function set_freq_all() {
  if [ "x$1" == "x" ];then
      echo "freq missed, please check the input freq !"
      exit -1
  fi
  echo "setting cpuinfo_freq -> ${1}"
  echo $1| sudo tee ${CPU_FREQ_ALL}/scaling_max_freq >/dev/null
  #echo $1| sudo tee ${CPU_FREQ_ALL}/cpuinfo_max_freq >/dev/null
  #echo $1| sudo tee ${CPU_FREQ_ALL}/cpuinfo_min_freq >/dev/null
}

function set_governor_all() {
  if [ "x$1" == "x" ];then
      echo "freq missed, please check the input freq !"
      exit -1
  fi
  echo "setting scaling_governor -> ${1}"
  echo $1 | sudo tee ${CPU_FREQ_ALL}/scaling_governor >/dev/null
}

function options_parse() {
   if [ $# -eq 0 ];then
       show
       exit -1
   fi
    while test $# -gt 0; do
        case "$1" in
            --freq)
                shift
                if [ x"$1" != x"-*" ];then
                    OPT_FREQ=$1
                fi
                set_freq_all ${OPT_FREQ}
                ;;
            -v|--verbose)
                OPT_VERBOSE=true
                show
                ;;
            --gov)
                shift
                if [ x"$1" != x"-*" ];then
                    OPT_GOVERNOR=$1
                fi
                set_governor_all ${OPT_GOVERNOR}
                ;;
            --show)
                show
                ;;
            -*)
                usage
                exit 1
                ;;
            *)
                show
                ;;
        esac
        shift
    done
}

# options parsing
echo $0 $@
echo ""
options_parse $@

echo "\ncomplete...."
