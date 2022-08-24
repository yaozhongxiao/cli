
# basic configuration for bashrc
export CLICOLOR=1
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#-------------git config---------------#
source ~/.git-completion.bash

[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

alias git-icommit="git -c user.email='zhongxiao.yzx@gmail.com' --author='zhongxiao.yzx<zhongxiao.yzx@gmail.com>' commit"

alias xcode="xed"

export JAVA11=/Library/Java/JavaVirtualMachines/jdk-11.0.11.jdk/Contents/Home
export JAVA_HOME=${JAVA11}
export PATH=$JAVA_HOME/bin:$PATH
export CLASS_PATH=$JAVA_HOME/lib

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#-------------------  compiler config begin ----------------#
alias clang-inspect="clang -dM -E -x c /dev/null"
alias gcc-inspect="gcc -dM -E -x c /dev/null"
#-------------------  compiler config end ------------------#

#-------------------  xcode config begin ----------------#
alias simopen="open -a Simulator"
alias simctl="xcrun simctl"
alias xcdevice="xcrun xcdevice"
alias xccov="xcrun xccov"
PodSrc=/Library/Ruby/Gems/2.6.0/gems/cocoapods-1.8.4/lib/cocoapods
alias podsrc="echo ${PodSrc}"
#-------------------  xcode config end ------------------#

#-------------------  android-ndk config begin ----------------#
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk
export ANDROID_NDK_R21B=${ANDROID_NDK_HOME}/21.1.6352462
export ANDROID_NDK=${ANDROID_NDK_R21B}
export ARM_TOOL_CHAIN=${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin
export ARM64_TOOL_CHAIN=${ANDROID_NDK}/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin
export PATH=${ANDROID_NDK}:$PATH
export PATH=${ARM_TOOL_CHAIN}:$PATH
export PATH=${ARM64_TOOL_CHAIN}:$PATH
#-------------------  android-ndk config end ------------------#

#-------------------  android-sdk config begin ----------------#
export ANDROID_SDK_ROOT=${ANDROID_HOME}
export PATH=${ANDROID_SDK_ROOT}/platform-tools:$PATH
export PATH=${ANDROID_SDK_ROOT}/emulator:$PATH
export PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:$PATH
export PATH=${ANDROID_SDK_ROOT}/tools/bin:$PATH
# export ANDROID_AVD_HOME=~/.android/avd
#-------------------  android-sdk config end ------------------#

#-------------------  docs begin ----------------#
source /Users/zhongxiao.yzx/Workspace/DevTools/cli/docs/docs.bash
#-------------------  docs end ------------------#

#------------------- cli cmd begin ----------------#
source /Users/zhongxiao.yzx/Workspace/DevTools/cli/cmd/cli-config.bash
#------------------- cli cmd end ------------------#
