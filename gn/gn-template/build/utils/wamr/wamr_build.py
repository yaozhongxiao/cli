#!/usr/bin/env python3
#
# Copyright 2022 WorkGroup Participants. All rights reserved
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

import argparse
import os
import shutil
import subprocess
import sys

def main():
  parser = argparse.ArgumentParser(
                epilog=__doc__,
                formatter_class=argparse.RawDescriptionHelpFormatter)
  parser.add_argument('sources', help='input file')
  parser.add_argument('-b', '--builder', required=True,
                      help='build scirpt')
  parser.add_argument('-o', '--output', required=True,
                      help='output directory')
  args = parser.parse_args()

  wamr_build_cmd = """sh %s --wamr %s --install %s """ %(args.builder, args.sources, args.output)

  subprocess.check_call(wamr_build_cmd, shell=True)
  sys.exit(0)

if __name__ == '__main__':
  sys.exit(main())