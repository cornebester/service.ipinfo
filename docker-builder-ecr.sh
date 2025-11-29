#!/bin/bash

set -ex

aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 146632099925.dkr.ecr.eu-west-1.amazonaws.com

PARENT_DIR=$(basename "${PWD%/*}")
CURRENT_DIR="${PWD##*/}"
IMAGE_NAME="$CURRENT_DIR"
TAG="${1}"

REGISTRY="146632099925.dkr.ecr.eu-west-1.amazonaws.com/misc"

docker build -t ${IMAGE_NAME}:${TAG} .
docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:latest    # tag new (local) image as latest
docker push ${REGISTRY}/${IMAGE_NAME}:latest # push new image with latest tag to ecr
docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:${TAG} # add version tag to local latest image
docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:latest # add latest tag to local latest image
docker push ${REGISTRY}/${IMAGE_NAME}:${TAG} # add version tag to latest image in ecr

var=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
echo "${var}","${REGISTRY}/${IMAGE_NAME}:${TAG}" >> version.txt