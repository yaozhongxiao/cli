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

ENABLE_NINJA=false
BUILD_TYPE=Debug
ACTION_FORCE=false
COMMANDS=()

function usage() {
    cat << EOF
    Usage: $0 [options]
    Options:
        -h|--help         This Message.
        -f|--force        Force Building.
        --ninja           Build With ninja (default is makefile)
        -d|--debug        Build With Debug Mode (default)
        -r|--release      Build With Release Mode
EOF
}

function options_parse() {
    while test $# -gt 0; do
        case "$1" in
            --ninja)
                ENABLE_NINJA=true
                ;;
            -d|--debug)
                BUILD_TYPE=Debug
                ;;
            -r|--release)
                BUILD_TYPE=Release
                ;;
            -f|--force)
                ACTION_FORCE=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Unknown option \"$1\"." >&2
                usage
                exit 1
                ;;
            *)
                COMMANDS+=($1)
                ;;
        esac
        shift
    done
}