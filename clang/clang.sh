#!/usr/bin/env bash
#
# Copyright 2023 WorkGroup Participants. All rights reserved
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
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
source ${SCRIPT_DIR}/../env.sh

function usage() {
  cat << EOF
    Usage: $0 [options]
    Options:
    -h|--help         This Message.
    -f|--force        Force Building.
    -dM               Print macro definitions
EOF
  exit 0
}

function print_clang_macro() {
  clang -dM -E - < /dev/null
  exit;
}

FORCE_OPT=false
function options_parse() {
    while test $# -gt 0; do
        case "$1" in
            -dM)
              print_clang_macro;
              ;;
            -f|--force)
              FORCE_OPT="-f"
              ;;
            -h|--help)
              usage
              ;;
            *)
              usage
              ;;
        esac
        shift
    done
}

# parse cli options
echo $0 $@
options_parse $@