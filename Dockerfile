##############################################################################
##                                 Base Image                               ##
##############################################################################
ARG ROS_DISTRO=noetic
FROM ros:${ROS_DISTRO}-ros-base
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

##############################################################################
##                                 Global Dependecies                       ##
##############################################################################
RUN apt-get update && apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-rviz \
    libeigen3-dev \
    libpcl-dev \
    python3-pip \
    python3-pcl \
    libopencv-dev python3-opencv \
    python3-scipy \
    python3-sklearn \
    python3-yaml \
    apt-utils \
    bash \
    nano \
    git \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install transforms3d pyyaml mayavi

##############################################################################
##                                 Create User                              ##
##############################################################################
ARG USER=docker
ARG PASSWORD=docker
ARG UID=1000
ARG GID=1000
ENV UID=${UID}
ENV GID=${GID}
ENV USER=${USER}
RUN groupadd -g "$GID" "$USER"  && \
    useradd -m -u "$UID" -g "$GID" --shell $(which bash) "$USER" -G sudo && \
    echo "$USER:$PASSWORD" | chpasswd && \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudogrp
RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /etc/bash.bashrc
RUN echo "export ROS_MASTER_URI=http://localhost:11311/" >> /home/$USER/.bashrc

USER $USER 

##############################################################################
##                                 User Dependecies                         ##
##############################################################################
WORKDIR /home/$USER

RUN git clone --recurse-submodules https://github.com/HViktorTsoi/ACSC

WORKDIR /home/$USER/ACSC/ros/livox_calibration_ws
RUN sudo apt update && rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y

WORKDIR /home/$USER/ACSC/segmentation
RUN sudo python3 setup.py install
##############################################################################
##                                 Build ROS and run                        ##
##############################################################################
WORKDIR /home/$USER/ACSC/ros/livox_calibration_ws
RUN . /opt/ros/$ROS_DISTRO/setup.sh && catkin_make
RUN echo "source /home/$USER/ACSC/ros/livox_calibration_ws/devel/setup.bash" >> /home/$USER/.bashrc
RUN echo "export LC_NUMERIC="en_US.UTF-8" " >> ~/.bashrc

RUN sudo sed --in-place --expression \
    '$isource "/home/$USER/ACSC/ros/livox_calibration_ws/devel/setup.bash"' \
    /ros_entrypoint.sh

RUN sudo sed --in-place --expression \
    '$iexport ROS_MASTER_URI=http://localhost:11311/' \
    /ros_entrypoint.sh

CMD /bin/bash
