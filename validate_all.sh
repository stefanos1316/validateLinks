#!/bin/bash

# This script is responsible for identifying the broken links by sending http requests.
# As the first command line argument provide the directory to do the search, 
# if not by default it will be the current working directory

DIR=$1
LINKDIR=$DIR

# egrep -ro 'https?://[^ ]+' * | uniq | sort

while read LINE; do
  curl -o /dev/null --silent --head --write-out "---%{http_code}---$LINE\n" "$LINE"
done< <(egrep -ro 'https?://[^ ]+' $DIR | sort | awk -v var="${LINKDIR}" -F ":" 'var=$1 {print $2":"$3}' | tr -d '}' | tr -d ',' | tr -d '"' | tr -d ')' | tr -d '(' | sed 's/\.$//' | uniq )

