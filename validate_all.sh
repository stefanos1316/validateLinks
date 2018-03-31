#!/bin/bash

# This script is responsible for identifying the broken links by sending http requests.
# As the first command line argument provide the directory to do the search, 
# if not by default it will be the current working directory

DIR=$1
LINKDIR=$DIR

STATUS_000=0

# Variables of 2xx Success
STATUS_200=0
STATUS_201=0
STATUS_202=0
STATUS_203=0
STATUS_204=0
STATUS_205=0
STATUS_206=0
STATUS_207=0
STATUS_208=0
STATUS_226=0

# Variables for 3xx Redirectrion
STATUS_300=0
STATUS_301=0
STATUS_302=0
STATUS_303=0
STATUS_304=0
STATUS_305=0
STATUS_306=0
STATUS_307=0
STATUS_308=0

# Variables for 4xx Client errors
STATUS_400=0
STATUS_401=0
STATUS_402=0
STATUS_403=0
STATUS_404=0
STATUS_405=0
STATUS_406=0
STATUS_407=0
STATUS_408=0
STATUS_409=0
STATUS_410=0
STATUS_411=0
STATUS_412=0
STATUS_413=0
STATUS_414=0
STATUS_415=0
STATUS_416=0
STATUS_417=0
STATUS_418=0
STATUS_421=0
STATUS_422=0
STATUS_423=0
STATUS_424=0
STATUS_426=0
STATUS_431=0
STATUS_451=0
STATUS_428=0


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
			getLinkStatus $1/$i
		fi
	done
}

function getLinkStatus {

while read LINE; do
  curl -o /dev/null --silent --head --write-out "|---%{http_code}---| $LINE\n" "$LINE";
  #increaseStatus $LINE
done< <(egrep -ro 'https?://[^ ]+' $1 | sort | awk -F ":" '{print $1":"$2}' | tr -d '}' | tr -d ',' | tr -d '"' | tr -d ')' | tr -d '(' | tr -d ';' | sed 's/\.$//' | uniq )

}



function printFinalReport {

}


if [ -z "$DIR" ]
then
# Here we are giving '0' is the current depth of direcory
traverse . 0
else
traverse $1 0
fi	

exit
