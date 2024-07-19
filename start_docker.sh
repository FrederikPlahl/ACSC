#!/bin/sh
echo "Run Container"
xhost + local:root

docker run --name ACSC \
    --privileged \
    -it \
    -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    --gpus all \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/.Xauthority:/home/docker/.Xauthority \
    -v $PWD/bags:/home/docker/bags \
    --net host \
    --rm \
    --ipc host \
    ACSC/ros:noetic
