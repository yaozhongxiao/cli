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
  # FXIME():add branch options
  parser.add_argument('url', help='input file')
  parser.add_argument('-o', '--output', required=True,
                      help='output directory')
  parser.add_argument('-f', '--force', default=False, action='store_true',
                      help='force redownload from fresh')
  args = parser.parse_args()

  if os.path.exists(args.output):
    if args.force:
      print("force to download!")
      shutil.rmtree(args.output)
    else:
      return 0

  git_clone_cmd = """ git clone "%s" "%s" """ %(args.url, args.output)

  subprocess.check_call(git_clone_cmd, shell=True)
  print("git clone %s complete!" %(args.url))
  sys.exit(0)

if __name__ == '__main__':
  sys.exit(main())
