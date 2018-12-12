#!/bin/bash -e

DATABASE_USER=user
DATABASE_SCHEMA=mydatabase

DUMP_FILE=database.dmp
DUMP_DIR=/var/lib/postgresql/dumps

restore_dump() {
    pg_restore --username=${DATABASE_USER} --verbose --exit-on-error --format=custom --dbname=${DATABASE_SCHEMA} ${DUMP_DIR}/${DUMP_FILE}
}

restore_dump
