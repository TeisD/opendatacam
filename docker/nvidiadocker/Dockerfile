ARG CUDA_VERSION=9.1
ARG CUDNN_VERSION=7
ARG UBUNTU_VERSION=16.04

# This is a dev image, needed to compile OpenCV with CUDA
FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS build

ENV OPENCV_VERSION=4.1.1
# TODO: CHANGE BACK TO OPENDATACAM
ENV OPENDATACAM_REPO=https://github.com/teisd/opendatacam

# Install OpenCV dependencies
RUN apt update && apt purge *libopencv* && apt install -y \
    # Essential OpenCV dependencies
    build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev curl wget unzip \
    # Gstreamer libs
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-libav \
    # FFMPEG
    ffmpeg \
    # Image & video libraries
    zlib1g-dev  libwebp-dev libtbb2 libtbb-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libgtk2.0-dev

WORKDIR /var/local

# Install OpenCV
RUN wget -nv --show-progress --progress=bar:force:noscroll https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip -O opencv.zip && \
    unzip opencv.zip && \
    mv opencv-${OPENCV_VERSION} opencv && \
    rm opencv.zip

WORKDIR /var/local/opencv/build

RUN ls /var/local/opencv/ && cmake \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D WITH_GSTREAMER=ON \
        -D WITH_GSTREAMER_0_10=OFF \
        -D WITH_CUDA=OFF \
        -D WITH_TBB=ON \
        -D WITH_LIBV4L=ON \
        -D WITH_FFMPEG=ON \
        -DOPENCV_GENERATE_PKGCONFIG=ON \
        .. && \
    # make -j8 if CPU has 8 cores to speed up things
    make -j8 && \
    make install

WORKDIR /var/local

RUN rm -r opencv

# Checkout and build darknet
# for debug
# apt-get install -y --no-install-recommends vim 

#FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime-ubuntu18.04

# Copy the compiled OpenCV libs
#COPY --from=build /usr/lib/lib* /usr/local/lib/
#COPY --from=build /usr/local/lib/* /usr/local/lib/
#COPY --from=build /usr/local/include/* /usr/local/include/
#COPY --from=build /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/

# Install the required GStreamer libs
#RUN  apt-get update -y && apt-get install -y \
#            libgstreamer1.0-0 \
#            gstreamer1.0-plugins-base \
#            gstreamer1.0-plugins-good \
#            gstreamer1.0-libav 
#RUN apt-get install -y gstreamer1.0-tools

RUN git clone --depth 1 -b odc https://github.com/opendatacam/darknet /var/local/darknet

WORKDIR /var/local/darknet

RUN mkdir /var/local/darknet/videos && \
    mkdir /var/local/darknet/weights && \
    sed -i -e s/GPU=0/GPU=1/ Makefile && \
    sed -i -e s/CUDNN=0/CUDNN=1/ Makefile && \
    sed -i -e s/OPENCV=0/OPENCV=1/ Makefile && \
    make

# Install node.js
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs

# Install mongodb
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 && \
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends openssl libcurl3 mongodb-org

VOLUME ["/data/db"]

# Technique to rebuild the docker file from here : https://stackoverflow.com/a/49831094/1228937
# Build using date > marker && docker build .
# date > marker && sudo docker build -t opendatacam .
#COPY marker /dev/null
RUN git clone --depth 1 -b development ${OPENDATACAM_REPO} /var/local/opendatacam

WORKDIR /var/local/opendatacam

# Build
RUN npm install && npm run build

EXPOSE 8080 8070 8090 27017

# Use the script to start mongodb and opendatacam
# TODO: change to docker-compose, once there is support for GPU
RUN cp docker/start.sh start.sh && \
    chmod 777 start.sh

CMD ./start.sh
