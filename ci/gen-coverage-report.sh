#!/bin/bash

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
PORJ_DIR=${SCRIPT_DIR}/../..

# list all the binary should collect the coverage
declare test_cases=(
  "test"
)

HOST_OS='unknown'
if [ "$(uname)" == "Darwin" ];then
  HOST_OS='mac'
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ];then
  HOST_OS='linux64'
else
  echo "please check the os type, because it's undefined yet!"
  exit -1
fi

command -v llvm-cov >/dev/null 2>&1 || {
  COV_TOOLS_DIR=${PORJ_DIR}/tools/llvm/${HOST_OS}/bin
  echo "export ${COV_TOOLS_DIR}"
  export PATH=${COV_TOOLS_DIR}:${PATH}
}

cd ${PORJ_DIR}

# TODO() set the target and report according to
# the script commandline args
testing_target="test"
if [ ! -z $1 ];then
  testing_target=$1
fi
out_dir="${PORJ_DIR}/out/Default"
report_dir="${PORJ_DIR}/out/report"
timestamp=`date +%Y%m%d%H%M%S`
profdata_file="${out_dir}/${testing_target}"
export LLVM_PROFILE_FILE="${profdata_file}.profraw"

# only build test if not exits
if [ ! -f ${out_dir}/${testing_target} ]; then
  # 1. gen with coverage args
  gn gen ${out_dir} --args="use_clang_coverage = true
                            is_debug = true
                            is_test = true
                            is_asan = true
                            is_ubsan = true
                            "
  # 2. build testing
  ninja -C ${out_dir} ${testing_target}
fi

# 3. run tests
# TODO(): we just gather the coverage by running in develop machine
# which need to override the tests runner for each platform(android, ios)

# test data of many tests relate to root_out_dir
cd ${out_dir}
${out_dir}/${testing_target}
cd ${PORJ_DIR}

# 4. merge profraw data
ls ${out_dir}/*profraw > ${SCRIPT_DIR}/test_suits.txt
cat ${SCRIPT_DIR}/test_suits.txt
llvm-profdata merge -o ${profdata_file}.profdata --input-files=${SCRIPT_DIR}/test_suits.txt

# 5. filter out all test binaries
declare all_test_binaries=()
for((i=0; i<${#test_cases[@]}; i++))
do
  out_bin="${out_dir}/${test_cases[i]}"
  if [ -f ${out_bin} -a -f ${out_bin}.profraw ];then
    all_test_binaries[${#all_test_binaries[@]}]="-object=${out_bin}"
  else
    echo "${out_bin} missed !"
  fi
done

echo "all_test_binaries:"
for((i=0; i<${#all_test_binaries[@]}; i++))
do
  out_bin="${all_test_binaries[i]}"
  echo "  [$i] : ${out_bin}"
done

# 6. gen html from coverage profdata
llvm-cov show -output-dir=${report_dir}/${testing_target}${timestamp} \
  -format=html \
  -instr-profile=${profdata_file}.profdata \
  -show-line-counts \
  -show-instantiations \
  -show-regions \
  -show-line-counts-or-regions \
  -ignore-filename-regex="third_party/*" \
  -ignore-filename-regex="testing/*" \
  -ignore-filename-regex=".*_unittest.cc" \
  ${all_test_binaries[@]}
  # -object=${out_dir}/lepus_unittests \
  # -object=${out_dir}/base_unittests \
  # -object=${out_dir}/${testing_target}
  #-compilation-dir=${out_dir}
  #-show-branches="count"
  #-show-expansions

echo ""
echo "check report in out/report/${testing_target}${timestamp}"
echo ""
