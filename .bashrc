
# basic configuration for bashrc
export CLICOLOR=1
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export JAVA11=/Library/Java/JavaVirtualMachines/jdk-11.0.11.jdk/Contents/Home
export JAVA_HOME=${JAVA11}
export PATH=$JAVA_HOME/bin:$PATH
export CLASS_PATH=$JAVA_HOME/lib

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

