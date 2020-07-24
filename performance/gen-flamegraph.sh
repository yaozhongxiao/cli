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

echo "$0"
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
FLAMEGRAPH_SCRIPT_DIR=${SCRIPT_DIR}/flamegraph

perf_data=$1
if [ -z ${perf_data} ];then
    echo "please provide the perf data"
fi

perf script -i ${perf_data} > perf_result.perf
perl ${FLAMEGRAPH_SCRIPT_DIR}/stackcollapse-perf.pl perf_result.perf > perf_result.folded
perl ${FLAMEGRAPH_SCRIPT_DIR}/flamegraph.pl perf_result.folded > perf_result.svg

