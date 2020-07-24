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

PROJECT_DIR=${SCRIPT_DIR}/..
BUILD_DIR=${PROJECT_DIR}/build
OUT_DOC_DIR=${PROJECT_DIR}/out/docs
mkdir -p ${OUT_DOC_DIR}

# NOTE : all the coverage infos are generated with
# the following building options
# add_compile_options(-g -fprofile-arcs -ftest-coverage)
# link_libraries(gcov -fprofile-arcs -ftest-coverage)
# set(BUILD_TESTS ON)

# log_and_exec lcov --zerocounters -d ${BUILD_DIR} --rc lcov_branch_coverage=1
# log_and_exec ${BUILD_DIR}/test/test --bindir ${BUILD_DIR}

# LCOV 1.10 has branch coverage disabled per default.
# You can enable it by modifying the lcovrc file (see man lcovrc)
# or by specifying --rc lcov_branch_coverage=1 when running lcov/genhtml.
lcov -c -d ${BUILD_DIR} -o ${BUILD_DIR}/test.info --rc lcov_branch_coverage=1
lcov --remove ${BUILD_DIR}/test.info '*/usr/*' '*/third_party/*' '*/build/*' '*/tools/*' '*/base/src/crypto/*' -o ${BUILD_DIR}/coverage.info --rc lcov_branch_coverage=1
genhtml ${BUILD_DIR}/coverage.info --branch-coverage -o ${OUT_DOC_DIR}/lcov --rc lcov_branch_coverage=1 --ignore-errors source --highlight

#tar cvf report.tar.gz report
