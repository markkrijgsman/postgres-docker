#!/bin/bash -e

REPOSITORY_NAME=markkrijgsman
IMAGE_NAME=database-dump-image
IMAGE_TAG=example-2
CONTAINER_NAME=database-dump-container

DATABASE_USER=user
DATABASE_PASSWORD=password
DATABASE_SCHEMA=mydatabase
DATABASE_PORT=5433

remove_existing_container() {
    if [ "$(docker ps -a -f name=${CONTAINER_NAME} | grep -w ${CONTAINER_NAME})" ]; then
        docker rm -vf ${CONTAINER_NAME}
    fi
}

start_new_container() {
    docker run -p ${DATABASE_PORT}:5432 --name ${CONTAINER_NAME} -e POSTGRES_USER=${DATABASE_USER} -e POSTGRES_PASSWORD=${DATABASE_PASSWORD} -e POSTGRES_DB=${DATABASE_SCHEMA} -d ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
}

remove_existing_container
start_new_container
