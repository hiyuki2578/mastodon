#!/bin/sh

Hash_rev=`git rev-parse --short HEAD`

sed -e "s/{Image_tag}/$Hash_rev/g" compose.yml > docker-compose.yml
