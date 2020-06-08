#!/bin/bash

echo "Starting opendatacam on platform: nano"

# Mount the configuration file
DOCKER_VOLUMES+="-v $(pwd)/config.json:/var/local/opendatacam/config.json "
# Mount a video directory for people to run on files
DOCKER_VOLUMES+="-v $(pwd)/data/videos:/var/local/darknet/videos:ro "
# Mount the directory containing neural network weights
DOCKER_VOLUMES+="-v $(pwd)/data/weights:/var/local/darknet/weights:ro "
# Mount the directory containing the database
DOCKER_VOLUMES+="-v $(pwd)/data/db:/data/db "
# Mount argus socket for CSI cam access
DOCKER_VOLUMES+="-v /tmp/argus_socket:/tmp/argus_socket "
shift
# We use --priviliged here because usb cam access cam be /dev/video0 or /dev/video1 or something else
# If you don't want to use --priviliged, you will need to manually mount the right --device in order for
# the docker container to be able to access it.. For example:
# --device=/dev/video0:/dev/video0
# We don't do that by default because if the device isn't mounted on this location, docker run will fail
# and we didn't find a way yet to be smart about this and guess which device to mount
# TODO change back to normal opendatacam image
# temporarily run with "sudo run.sh image-name"
# docker run -d --name opendatacam --restart unless-stopped --runtime nvidia -p 8080:8080 -p 8090:8090 -p 8070:8070 --privileged $DOCKER_VOLUMES $@ opendatacam/opendatacam:OPENDATACAM_VERSION-nano
docker run -d --name opendatacam --restart unless-stopped --runtime nvidia -p 8080:8080 -p 8090:8090 -p 8070:8070 --privileged $DOCKER_VOLUMES $@