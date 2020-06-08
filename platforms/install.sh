#!/bin/bash

# exit when any command fails
set -e

# Each opendatacam release should set the correct version here and tag appropriatly on github
# TODO: CHANGE BACK TO OPENDATACAM
#VERSION=v3.0.0-beta.2
VERSION=development
#BASE_URL=https://raw.githubusercontent.com/opendatacam/opendatacam
#BASE_URL=localhost:3000
BASE_URL=https://raw.githubusercontent.com/teisd/opendatacam

PLATFORM=undefined
INDEX=undefined

PLATFORM_OPTIONS=("nano" "tx2" "xavier" "nvidiadocker")

display_usage() {
  echo
  echo "Usage: $0"
  echo -n " -p, --platform   Specify platform "
  for i in "${PLATFORM_OPTIONS[@]}" 
  do
    echo -n "$i "
  done
  echo
  echo " -h, --help       Display usage instructions"
  echo
}

raise_error() {
  local error_message="$@"
  echo "${error_message}" 1>&2;
}

function index(){
  local elem=$1
  
  for i in "${!PLATFORM_OPTIONS[@]}" 
  do
    if [ ${PLATFORM_OPTIONS[$i]} == "${elem}" ]; then
      echo ${i}
    fi
  done
}

argument="$1"

if [[ -z $argument ]] ; then
  raise_error "Expected argument to be present"
  display_usage
  exit
fi

case $argument in
  -h|--help)
    display_usage
    ;;
  -p|--platform)

    INDEX=$( index $2)

    if [ "$INDEX" == "" ]
      then
        raise_error "Platform choice not correct"
        display_usage
        exit
    fi
    
    # Stop any current docker container from running
    echo "Stop any running docker container..."
    set +e
    sudo docker stop $(sudo docker ps -a -q)
    set -e

    # Platform is specified 
    PLATFORM=$2
    
    echo "Installing opendatacam $VERSION for platform: $PLATFORM ..."
    
    echo "Download run script for platform: $PLATFORM ..."
    # Get the run-docker script
    wget -nv --show-progress -N ${BASE_URL}/${VERSION}/platforms/${PLATFORM}/run.sh

    echo "Set the run script to version: $VERSION ..."
    sed -i -e "s/OPENDATACAM_VERSION/$VERSION/g" run.sh

    # Chmod to give exec permissions
    chmod +x run.sh
    
    # Get the config file
    echo "Download config file ..."
    wget -nv --show-progress -N ${BASE_URL}/${VERSION}/config.json -O config.default.json

    # Get the config file for the platform
    echo "Downloading platform-specific configuration  ..."
    wget -nv --show-progress -N ${BASE_URL}/${VERSION}/platforms/${PLATFORM}/config.json -O config.platform.json

    # Merge the configuration files
    sed ';$d' config.platform.json > config.json
    truncate -s-1 config.json
    echo "," >> config.json
    sed '1d' config.default.json >> config.json
    rm config.default.json
    rm config.platform.json

    # Create the directories to store data
    echo "Creating data directories"
    mkdir -p data/db
    mkdir -p data/videos
    mkdir -p data/weights

    echo "Download demo video ..."
    wget -nv --show-progress -N ${BASE_URL}/${VERSION}/public/static/demo/demo.mp4 -O data/videos/demo.mp4

    # Run additional 
    echo "Download default neural network weights ..."
    wget -nv --show-progress -N ${BASE_URL}/${VERSION}/platforms/${PLATFORM}/DEFAULT_NEURAL_NETWORK
    wget -N -i DEFAULT_NEURAL_NETWORK
    rm DEFAULT_NEURAL_NETWORK

    echo "Download, install and run opendatacam docker container"
    sudo ./run.sh

    # Message that docker container has been started and opendatacam will be available shorty on <IP>
    echo "OpenDataCam docker container installed successfully, it might take up to 1-2 min to start the node app and the webserver"
    
    # Cancel stop bash script on error (get IP will fail is no wifi dongle / ethernet connexion)
    set +e
    # TODO better way to get the ip to run
    wifiIP=$(ifconfig wlan0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    ethernetIP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.2')
    
    if [ -n "$wifiIP" ]; then
      echo "WIFI device IP"
      echo "OpenDataCam is available at: http://$wifiIP:8080"
    fi

    if [ -n "$ethernetIP" ]; then
      echo "Ethernet device IP"
      echo "OpenDataCam is available at: http://$ethernetIP:8080"
    fi

    echo "OpenDataCam will start automaticaly on boot when you restart you jetson"
    echo "If you want to stop it, please refer to the doc: https://github.com/opendatacam/opendatacam"

    ;;
  *)
    raise_error "Unknown argument: ${argument}"
    display_usage
    ;;
esac

