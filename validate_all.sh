#!/bin/bash

# This script is responsible for identifying the broken links by sending http requests.
# As the first command line argument provide the directory to do the search, 
# if not by default it will be the current working directory

DIR=$1
LINKDIR=$DIR

STATUS_SUCCESS=0
STATUS_REDIRECT=0
STATUS_CLIENT_ERROR=0
STATUS_SERVER_ERROR=0


# Function declarations
function depth {

	#Do a small depth checking how deep into the tree we are
	k=0
	while [ $k -lt $1 ]; do
		echo -n " "
		let k++
	done
}

function traverse {

	# Fix this one ...
	# ls "$1" | while read i
	while read i; 
	do
		depth $2
		if [ -d "$1/$i" ]
		then
			echo Directory: $1/$i
			traverse "$1/$i" `expr $2 + 1`
		else
			echo File: $1/$i
			# Calling function to check the status of the $i file's link 
			getLinkStatus $1/$i
		fi
	done< <(ls "$1")
}

function getLinkStatus {

while read LINE; do
   URL=$(curl -o /dev/null --silent --head --write-out "|%{http_code}| $LINE\n" "$LINE")
   echo $URL 
   increaseStatus $URL
done< <(egrep -ro 'https?://[^ ]+' $1 | sort | awk -F ":" '{print $1":"$2}' | tr -d '}*' | tr -d ',' | tr -d '"' | tr -d ')' | tr -d '(' | tr -d ';' | sed 's/\.$//' | uniq )

}

function increaseStatus {

	STATUS=$(echo $1 | awk -F "|" '{print $2}')

	# This long case statement is responsible for increasing the STATUS variable counts
 	if [ $STATUS -lt 300 ]; then
		((++STATUS_SUCCESS))
	elif [ $STATUS -lt 400 ]; then
		((++STATUS_REDIRECT))
	elif [ $STATUS -lt 500 ]; then
		 ((++STATUS_CLIENT_ERROR))
	elif [ $STATUS -lt 600 ]; then
		 ((++STATUS_SERVER_ERROR))
	else
		echo "Such status don't exist."
	fi
}

function printReports {
echo ""
echo "[Report] Total link's STATUS"
echo "============================"
echo "$STATUS_SUCCESS Success links"
echo "$STATUS_REDIRECT Redirection links"
echo "$STATUS_CLIENT_ERROR Client error links"
echo "$STATUS_SERVER_ERROR Server error links"

}


if [ -z "$DIR" ]
then
# Here we are giving '0' is the current depth of direcory
traverse . 0
else
traverse $1 0
fi	

printReports

exit
