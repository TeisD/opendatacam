#!/bin/bash

echo "Starting opendatacam on platform: nvidia-docker"

# Mount the configuration file
DOCKER_VOLUMES+="-v $(pwd)/config.json:/var/local/opendatacam/config.json "
# Mount a video directory for people to run on files
DOCKER_VOLUMES+="-v $(pwd)/data/videos:/var/local/darknet/videos:ro "
# Mount the directory containing neural network weights
DOCKER_VOLUMES+="-v $(pwd)/data/weights:/var/local/darknet/weights:ro "
# Mount the directory containing the database
DOCKER_VOLUMES+="-v $(pwd)/data/db:/data/db "
shift
# If usbcam add --device=/dev/video0:/dev/video0 ... Will improve to detect and add it auto from config.json
# TODO change back to normal opendatacam image
# temporarily run with "sudo run.sh image-name"
# docker run -d --name opendatacam --restart unless-stopped --gpus=all -p 8080:8080 -p 8090:8090 -p 8070:8070 $DOCKER_VOLUMES $@ opendatacam/opendatacam:OPENDATACAM_VERSION-nvidiadocker
docker run -d --name opendatacam --restart unless-stopped --gpus=all -p 8080:8080 -p 8090:8090 -p 8070:8070 $DOCKER_VOLUMES $@
