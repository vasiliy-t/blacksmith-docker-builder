#!/bin/sh

docker rm -fv $COMMIT

# Create a data container to share source code
# across the builders
docker create -v /$COMMIT \
       --name $COMMIT \
       tianon/true:latest true

# Get source to build
docker run \
       --volumes-from $COMMIT \
       --workdir "/$COMMIT" \
       --entrypoint=/bin/sh  \
       leanlabs/git:latest -c "/usr/bin/git -C ./ init && \
/usr/bin/git -C ./ fetch $REPOSITORY_GIT_HTTP_URL $REF && \
/usr/bin/git -C ./ checkout $COMMIT"

# Build Docker image
docker run --rm \
       -e COMMAND=build \
       -e IMAGE=$DOCKER_IMAGE_NAME \
       --volumes-from $COMMIT \
       -v /var/run/docker.sock:/var/run/docker.sock \
       --workdir /$COMMIT \
       leanlabs/image-builder

# Publish docker image
docker run --rm \
       -e DOCKER_HUB_USERAME=$DOCKER_HUB_USERNAME \
       -e DOCKER_HUB_PASSWORD=$DOCKER_HUB_PASSWORD \
       -e DOCKER_IMAGE_NAME=$DOCKER_IMAGE_NAME \
       -e DOCKER_IMAGE_TAG=latest \
       -v /var/run/docker.sock:/var/run/docker.sock \
       leanlabs/docker-hub-publisher
