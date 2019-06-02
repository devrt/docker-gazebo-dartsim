FROM ros:kinetic

MAINTAINER Yosuke Matsusaka <yosuke.matsusaka@gmail.com>

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y wget software-properties-common && apt-get clean

# install dependent packages
RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list' && \
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - && \
    apt-get update && \
    wget https://bitbucket.org/osrf/release-tools/raw/default/jenkins-scripts/lib/dependencies_archive.sh -O /tmp/dependencies.sh && \
    GAZEBO_MAJOR_VERSION=9 ROS_DISTRO=dummy . /tmp/dependencies.sh && \
    echo $BASE_DEPENDENCIES $GAZEBO_BASE_DEPENDENCIES | tr -d '\\' | xargs apt-get -y install && \
    rm /tmp/dependencies.sh && \
    apt-get clean

# install dartsim
RUN apt-add-repository -y ppa:dartsim && \
    apt-get update && \
    apt-get install -y libdart6-dev libdart6-utils-urdf-dev && \
    apt-get clean

# compile and install gazebo
RUN hg clone https://bitbucket.org/osrf/gazebo /tmp/gazebo && \
    cd /tmp/gazebo/ && \
    hg checkout gazebo9 && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr . && \
    make -j$(nproc) install && \
    ldconfig && \
    cd && rm -r /tmp/gazebo

# compile and install gazebo_ros_plugin
RUN mkdir -p /tmp/catkin_ws/src && \
    cd /tmp/catkin_ws/src && \
    git clone https://github.com/ros-simulation/gazebo_ros_pkgs.git -b kinetic-devel && \
    cd /tmp/catkin_ws && \
    sed -i 's|<build_export_depend>libgazebo7-dev</build_export_depend>||g' src/gazebo_ros_pkgs/gazebo_dev/package.xml && \
    sed -i 's|<exec_depend>gazebo</exec_depend>||g' src/gazebo_ros_pkgs/gazebo_dev/package.xml && \
    /ros_entrypoint.sh rosdep update && \
    /ros_entrypoint.sh rosdep install --from-paths src --ignore-src --rosdistro kinetic -y && \
    /ros_entrypoint.sh catkin_make install -DCMAKE_INSTALL_PREFIX=/opt/ros/kinetic && \
    cd && rm -r /tmp/catkin_ws
