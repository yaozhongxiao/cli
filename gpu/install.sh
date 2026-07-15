#!/usr/bin/env bash
#
# Copyright 2025 WorkGroup Participants. All rights reserved
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
DEVTOOLS_DIR=${SCRIPT_DIR}/..

# # source ${SCRIPT_DIR}/../env.sh
# 
# bash_file=~/.bashrc
# $xsed "/git config begin/,/git config end./ d" ${bash_file}
# echo '#------------------- git config begin ----------------#' >> ${bash_file}
# echo 'source ~/.git-completion.bash' >> ${bash_file}
# echo "alias lic=\"git -c user.email='yaozhongxiao@lixiang.com' commit --author='yaozhongxiao<yaozhongxiao@lixiang.com>'\"" >> ${bash_file}
# echo "alias repo-branch='repo forall -c \"echo Repository: \\\$REPO_PATH; git branch -r\"'">> ${bash_file}
# echo "alias repo-fetch='_f(){ repo forall -vc git fetch -v "\$1";};_f'">> ${bash_file}
# echo '#------------------- git config end ----------------#' >> ${bash_file}

echo "gpu config install complete ! ..."