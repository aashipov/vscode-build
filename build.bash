#!/bin/bash

set -x

DUMMY_USER="dummy"
CONTAINER_NAME=vscode
IMAGE="aashipov/docker:vscode"
HOST_DIR=${HOME}/${CONTAINER_NAME}-buildbed
THIS_DIR="$(pwd)"
ENTRYPOINT_BASH="entrypoint.bash"
VOLUMES="-v ${HOST_DIR}:/dummy:rw -v ${THIS_DIR}/${ENTRYPOINT_BASH}:/${DUMMY_USER}/${ENTRYPOINT_BASH}:ro"
CMD="bash /${DUMMY_USER}/${ENTRYPOINT_BASH}"

docker pull ${IMAGE}
if [[ $? -ne 0 ]]
then 
    docker build --tag=${IMAGE} .
    docker push ${IMAGE}
fi
docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

mkdir -p ${HOST_DIR}
docker run -it --name=${CONTAINER_NAME} --hostname=${CONTAINER_NAME} -u=${DUMMY_USER}:${DUMMY_USER} ${VOLUMES} ${IMAGE} ${CMD}
