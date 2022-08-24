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

set - e

SCRIPT_DIR="$(cd "$(dirname "$0")";pwd -P)"
source ${SCRIPT_DIR}/../env.sh

cd ~

[ -f ~/.gitconfig ] && rm -rf ~/.gitconfig
ln -s ${SCRIPT_DIR}/.gitconfig  ~/.gitconfig

[ -f ~/.git-completion.bash ] && rm -rf ~/.git-completion.bash
ln -s ${SCRIPT_DIR}/.git-completion.bash .git-completion.bash

[ -f ~/.git-commit-template ] && rm -rf ~/.git-commit-template
ln -s ${SCRIPT_DIR}/.git-commit-template  .git-commit-template

$xsed "/git config begin/,/git config end./ d" ~/.bashrc
echo '#------------------- git config begin ----------------#' >> ~/.bashrc
echo 'source ~/.git-completion.bash' >> ~/.bashrc
echo "alias git-icommit=\"git -c user.email='zhongxiao.yzx@gmail.com' --author='zhongxiao.yzx<zhongxiao.yzx@gmail.com>' commit\"" >> ~/.bashrc
echo '#------------------- git config end ----------------#' >> ~/.bashrc

echo "git config install complete ! ..."
