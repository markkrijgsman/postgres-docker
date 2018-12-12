FROM postgres:9.5.10-alpine
MAINTAINER Mark Krijgsman <mark.krijgsman@luminis.eu>

RUN mkdir -p /var/lib/postgresql/dumps/
RUN curl -o /var/lib/postgresql/dumps/database.dmp https://raw.githubusercontent.com/markkrijgsman/postgres-docker/master/resources/database.dmp

COPY resources/initialize.sh /docker-entrypoint-initdb.d/
