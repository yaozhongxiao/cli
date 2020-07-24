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
#

# NOTE: detail information refers to
# https://www.kernel.org/doc/Documentation/trace/ftrace.txt

exec="" # echo | ""

trace_during_time=20
trace_buffer_size=32768
trace_force=false
trace_args=""

help() {
    echo ""
    echo "Usage: `basename $0` [options] [sched] [input]"
    echo "options:"
    echo "    -t time        : set the tracing time(seconds)"
    echo "    -f             : force to traceing"
    echo "    -b size        : the tracing data buffer(bytes)"
    echo "examples:"
    echo "  $(basename $0)"
    echo "        : keep tracing for default time and collect data into buffer with default size"
    echo "  $(basename $0) -t 10 -b 32768"
    echo "        : keep tracing for 10s and collect data into buffer with size 32768 bytes"
    exit 1
}

command_option_parser() {
    # parsing options for commands
    while [[ ! -z $1 ]]
    do
        case "$1" in
            -f)
                trace_force=true
                ;;
            -t)
                if [[ ! -z $2 && ! x$2 =~ x- ]];then
                    trace_during_time=$2
                    shift
                fi
                ;;
            -b)
                if [[ ! -z $2 && ! x$2 =~ x- ]];then
                    trace_buffer_size=$2
                    shift
                fi
                ;;
            -h)
                help
                ;;
            *)
                echo $@
                trace_args=$@
                ;;
         esac
         shift
    done
}

command_option_parser $@

EXECUTE_DIR=`pwd`
# echo "$0"
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
SYS_TRACE_DIR=${SCRIPT_DIR}/systrace

# check the os type
OS_TYPE=$(uname -s)
echo "\ncurrent os : ${OS_TYPE}"
if [ x${OS_TYPE} != x"Linux" -a x$1 != x"-f" ];then
    echo "only support ftrace in linux !"
    echo ""
    exit -1
fi
export PATH=${SYS_TRACE_DIR}:$PATH
# try to unzip the catapult systrace
cd ${SYS_TRACE_DIR}
if [ ! -d ${SYS_TRACE_DIR}/catapult/systrace ];then
    echo "tar -zxvf catapult.tar.gz ."
    tar -zxvf catapult.tar.gz
fi
cd ${SYS_TRACE_DIR}/catapult/systrace/systrace

if [ -f ${EXECUTE_DIR}/ftrace_report.html ];then
    cp -rf ${EXECUTE_DIR}/ftrace_report.html ${EXECUTE_DIR}/ftrace_report_bk.html
fi
echo ""
echo "current directory : `pwd`\n"

echo "sudo python run_systrace.py input ${trace_args} -b ${trace_buffer_size} --target=linux --time=${trace_during_time} -o ${EXECUTE_DIR}/ftrace_report.html\n"
${exec} sudo python run_systrace.py input ${trace_args} -b ${trace_buffer_size} --target=linux --time=${trace_during_time} -o ${EXECUTE_DIR}/ftrace_report.html

cd ${EXECUTE_DIR}
echo "done ..."
