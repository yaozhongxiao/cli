#!/usr/bin/bash
#
# Copyright 2020 Develop Group Participants. All right reserver.
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
set -e

SCRIPT_ROOT="$(cd "$(dirname "$0")"; pwd -P)"
CI_ROOT=${SCRIPT_ROOT}/..

if [ ! -f "${CI_ROOT}/build/benchmark/bm_test" ];then
  echo "can not find benchmark to run!"
  exit
fi

THRESHOLD=0.05
if [ ! -z $1 ];then
  THRESHOLD=$1
fi
BENCH_FILE=bench_file.json
BENCH_COMPARE_FILE=bench_compare.json
if [ -f ${BENCH_FILE} ];then
  rm -rf ${BENCH_FILE}
fi
cd ${CI_ROOT}/build

# generate benchmark
${CI_ROOT}/build/benchmark/bm_test --benchmark_out_format=json --benchmark_out=${BENCH_FILE}
PYTHON=python3
if ${PYTHON} -c "import scipy" >/dev/null 2>&1;then
  # generate benchmark compare
  ${PYTHON} ${SCRIPT_ROOT}/tools/compare.py -d ${BENCH_COMPARE_FILE} filters ${BENCH_FILE} "BM_.*Intrinsic" "BM_.*NativeSimd"
  # regression check
  ${PYTHON} ${SCRIPT_ROOT}/bench_check.py ${BENCH_COMPARE_FILE} ${THRESHOLD}
else
  # can not install scipy in aarch64, just skip now!
  echo "can not find scipy, skip benchmark compare!"
fi