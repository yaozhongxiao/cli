#!/bin/bash

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
PROJ_DIR=${SCRIPT_DIR}/../../
COV_TOOLS_DIR=${PROJ_DIR}/tools/llvm/bin

export PATH=${COV_TOOLS_DIR}:${PATH}
cd ${PROJ_DIR}

# TODO() set the target and report according to
# the script commandline args
out_dir="out/coverage"
testing_target="base_unittest"
timestamp=`date +%Y%m%d%H%M%S`
profdata_file="${out_dir}/${testing_target}-${timestamp}"
export LLVM_PROFILE_FILE="${profdata_file}.%4m.profraw"

# 1. gen with coverage args
gn gen ${out_dir} --args="use_clang_coverage=true"

# 2. build testing
ninja -C ${out_dir} ${testing_target}

# 3. run tests
# TODO(): we just gather the coverage by running in develop machine
# which need to override the tests runner for each platform(android, ios)
./${out_dir}/${testing_target}

# 4. merge profraw data
llvm-profdata merge -o ${profdata_file}.profdata ${profdata_file}.*.profraw

# 5. gen html from coverage profdata
llvm-cov show -output-dir=out/report/${testing_target}${timestamp} \
  -format=html \
  -instr-profile=${profdata_file}.profdata \
  -compilation-dir=${out_dir} \
  -object=${out_dir}/${testing_target} \
  -ignore-filename-regex="third_party/*" \
  -ignore-filename-regex="testing/*"

