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

trace_pid=""
trace_during_time=10
trace_frequency=1000

help() {
    echo ""
    echo "Usage: `basename $0` [options] [sched] [input]"
    echo "options:"
    echo "    -t time        : set the tracing time(seconds)"
    echo "    -f             : force to traceing"
    echo "    -p pid        : the tracing data buffer(bytes)"
    echo "examples:"
    echo "  $(basename $0) -t 10 -p 32768"
    echo "        : keep tracing for 10s for pid 32768"
    echo "# perf record -F 1000 -a -g out/bin/test-run xxx.wasm"
    exit 1
}

command_option_parser() {
    # parsing options for commands
    while [[ ! -z $1 ]]
    do
        case "$1" in
            -f)
                if [[ ! -z $2 && ! x$2 =~ x- ]];then
                    trace_frequency=$2
                    shift
                fi
                ;;
            -t)
                if [[ ! -z $2 && ! x$2 =~ x- ]];then
                    trace_during_time=$2
                    shift
                fi
                ;;
            -p)
                if [[ ! -z $2 && ! x$2 =~ x- ]];then
                    trace_pid=$2
                    shift
                fi
                ;;
            -h|*)
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

# 0. setup gcc and links
if [[ -z ${trace_pid} ]];then
    echo "pid is missed !"
    help;
fi

# perf record -F 1000 -a -g out/bin/test-run samples/contract-apis/log.wasm

# -F : frequency ; -p : pid
echo "sudo perf record -F ${trace_frequency} --call-graph dwarf -p ${trace_pid} -a -g --sleep ${trace_during_time} -o perf_trace_report.perf"
sudo perf record -F ${trace_frequency} --call-graph dwarf -p ${trace_pid} -a -g --sleep ${trace_during_time} -o perf_trace_report.perf

echo "done ..."

