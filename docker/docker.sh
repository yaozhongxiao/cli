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
container_name=sch_dev_scc
docker_registry_url="artifactory.ep.chehejia.com"
docker_image_url="${docker_registry_url}/cu-alg-soft-docker-release-local/cu-toolchain-build-ubuntu-20.04:latest"

pull_image=""
command="status"
force_option=true
work_dir=`pwd`
function usage() {
    cat << EOF
    Usage: $0 [options]
    Options:
      -h|--help          This Message.
      -n|--name          container name, default is sch_dev_scc
      --url              docker image url
      --docker-registry  docker registry url
      -f|--force         force to perform action, run, exec, etc.
      -w|--workdir       docker work dir, default is `pwd`
    Commands:
      start              start docker service
      status             display docker status
      exec               exec in run container
      run                start conainer and run in it
      login              login docker registry
EOF
}

function docker_login() {
    local docker_registry_url=$1
    echo "try to login docker registry"
    docker login ${docker_registry_url}
}
function docker_restart() {
    echo "try to restart docker service"
    systemctl restart docker
    sudo chmod 777 /var/run/docker.sock
    sleep 3
}
function docker_status() {
    ls -l /var/run/docker.sock
    echo "-----------------------------------"
    docker images
    echo ""
    echo "-----------------------------------"
    docker ps -a
    echo ""
    echo "-----------------------------------"
    systemctl status docker
}
function docker_exec() {
    local conainer_name=$1
    echo "try to exec in container[$conainer_name]"
    if [ "$(docker inspect -f '{{.State.Running}}' $conainer_name 2>/dev/null)" = "true" ]; then
        echo "$conainer_name is running"
        echo "docker exec in $work_dir"
        docker exec -it --user "$(id -u):$(id -g)" -w "$work_dir" $conainer_name /bin/bash
    else
        echo "$conainer_name is not running"
        docker start -i $conainer_name
    fi
}

function docker_run() {
    local conainer_name=$1
    local docker_image_url=$2
    echo "try to start container[$conainer_name] to run"
    if [ "${force_option}" = "true" ]; then
        docker rm -f $conainer_name
    fi
    echo "docker run in $work_dir"
    docker run -it \
      --name $conainer_name \
      --user "$(id -u):$(id -g)" \
      -v $(realpath ~/).ssh:$(realpath ~/).ssh:ro \
      -v $work_dir:$work_dir \
      -w  $work_dir $docker_image_url
}

function options_parse() {
    while test $# -gt 0; do
        case "$1" in
            -f|--force)
              force_option=true
              ;;
            -n|--name)
              container_name="$2"
              shift
              ;;
            -w|--workdir)
              work_dir=$(realpath $2)
              shift
              ;;
            --docker-registry)
              docker_registry_url="$2"
              shift
              ;;
            --url)
              docker_image_url="$2"
              pull_image=$(echo $docker_image_url | awk -F'/' '{print $NF}')
              command=run
              shift
              ;;
            -*|-h|--help)
                usage
                exit 1
                ;;
            *)
                command="$1"
                ;;    
        esac
        shift
    done
}

# parse cli options
echo $0 $@
options_parse $@

if [ -n "$pull_image" ]; then
    echo "try to pull image[$docker_image_url]"
    docker pull $docker_image_url
fi

case "$command" in
    start)
        docker_restart
        ;;
    status)
        docker_status
        ;;
    exec)
        docker_exec $container_name
        ;;
    run)
        docker_run $container_name $docker_image_url
        ;;
    login)
        docker_login $docker_registry_url
        ;;
    *)
        echo "undefined command[$command]"
        usage
        exit 1
        ;;
esac
