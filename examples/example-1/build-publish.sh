#!/bin/bash -e

REPOSITORY_NAME=markkrijgsman
BASE_IMAGE_NAME=postgres:9.5.10-alpine
IMAGE_NAME=database-dump-image
IMAGE_TAG=example-1
CONTAINER_NAME=database-dump-container

DATABASE_USER=user
DATABASE_PASSWORD=password
DATABASE_SCHEMA=mydatabase
DATABASE_PORT=5432

DOWNLOAD_DIR=../../resources
DUMP_DIR=/var/lib/postgresql/dumps
DUMP_FILE=database.dmp
DUMP_HOST=https://raw.githubusercontent.com/markkrijgsman/postgres-docker/master/resources/${DUMP_FILE}

remove_existing_container() {
    if [ "$(docker ps -a -f name=${CONTAINER_NAME} | grep -w ${CONTAINER_NAME})" ]; then
        docker rm -vf ${CONTAINER_NAME}
    fi
}

start_container() {
    docker run -p ${DATABASE_PORT}:5432 --name ${CONTAINER_NAME} -e POSTGRES_USER=${DATABASE_USER} -e POSTGRES_PASSWORD=${DATABASE_PASSWORD} -e POSTGRES_DB=${DATABASE_SCHEMA} -d ${BASE_IMAGE_NAME}
    sleep 10
}

fill_container() {
    docker exec -i ${CONTAINER_NAME} mkdir -p ${DUMP_DIR}
    curl -o ${DOWNLOAD_DIR}/${DUMP_FILE} ${DUMP_HOST}
    docker cp ${DOWNLOAD_DIR}/${DUMP_FILE} ${CONTAINER_NAME}:${DUMP_DIR}
    docker exec -i ${CONTAINER_NAME} pg_restore --username=${DATABASE_USER} --verbose --exit-on-error --format=custom --dbname=${DATABASE_SCHEMA} ${DUMP_DIR}/${DUMP_FILE}
}

publish_container() {
    docker commit ${CONTAINER_NAME} ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
    docker push ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
}

remove_existing_container
start_container
fill_container
publish_container
