#!/bin/bash -e

REPOSITORY_NAME=markkrijgsman
IMAGE_NAME=database-dump-image
IMAGE_TAG=example-2
CONTAINER_NAME=database-dump-container

DATABASE_USER=user
DATABASE_PASSWORD=password
DATABASE_SCHEMA=mydatabase
DATABASE_PORT=5432

DUMP_FILE=database.dmp
DUMP_DIR=/var/lib/postgresql/dumps

remove_existing_container() {
    if [ "$(docker ps -a -f name=${CONTAINER_NAME} | grep -w ${CONTAINER_NAME})" ]; then
        docker rm -vf ${CONTAINER_NAME}
    fi
}

start_container() {
    docker build --rm=true -t ${IMAGE_NAME} ../../
    docker run -p ${DATABASE_PORT}:5432 --name ${CONTAINER_NAME} -e POSTGRES_USER=${DATABASE_USER} -e POSTGRES_PASSWORD=${DATABASE_PASSWORD} -e POSTGRES_DB=${DATABASE_SCHEMA} -d ${IMAGE_NAME}
    sleep 10
}

publish_container() {
    docker commit ${CONTAINER_NAME} ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
    docker push ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
}

remove_existing_container
start_container
publish_container
