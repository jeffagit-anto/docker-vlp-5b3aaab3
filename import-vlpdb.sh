#!/bin/bash

# create vlp_data db
docker-compose exec db psql -U vlp -c 'create database vlp_data;'

# unzip vlp_data dump and pipe to psql in db container
gunzip -c vlp_data-201009.sql.gz | docker-compose exec -T db psql -U vlp -f - vlp_data
