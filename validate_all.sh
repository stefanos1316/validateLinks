#!/bin/bash

# This script is responsible for identifying the broken links by sending http requests.
# As the first command line argument provide the directory to do the search, 
# if not by default it will be the current working directory

DIR=$1
LINKDIR=$DIR

function depth {

	#Do a small depth checking how deep into the tree we are
	k=0
	while [ $k -lt $1 ]; do
		echo -n " "
		let k++
	done
}

function traverse {

	ls "$1" | while read i
	do
		depth $2
		if [ -d "$1/$i" ]
		then
			echo Directory: $1/$i
			traverse "$1/$i" `expr $2 + 1`
		else
			echo File: $1/$i
			# Calling function to check the status of the $i file's link 
			echo "Checking link of $1/$i..."
			sleep 5
			getLinkStatus $1/$i
		fi
	done
}

function getLinkStatus {

while read LINE; do
  curl -o /dev/null --silent --head --write-out "---%{http_code}---$LINE\n" "$LINE"
done< <(egrep -ro 'https?://[^ ]+' $1 | sort | awk -F ":" '{print $2":"$3}' | tr -d '}' | tr -d ',' | tr -d '"' | tr -d ')' | tr -d '(' | sed 's/\.$//' | uniq )

}


if [ -z "$DIR" ]
then
# Here we are giving '0' is the current depth of direcory
traverse . 0
else
traverse $1 0
fi	

exit
