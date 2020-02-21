#!/bin/sh

# Variables
DOCKER_CMD=$1

# echo $DOCKER_CMD

if [ "$DOCKER_CMD" = "build" ]; then
  # docker build -t hexo .
  docker build \
    --file Dockerfile \
    -t oracle-xe:18c .
elif [ "$DOCKER_CMD" = "run" ]; then
  docker run -it --rm \
    --entrypoint /bin/ash \
    oracle-xe:18c
fi