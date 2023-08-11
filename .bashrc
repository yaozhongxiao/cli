# basic configuration for bashrc
export PS1='[\u@ \w] '

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

