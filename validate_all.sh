#!/bin/bash

# This script is responsible for identifying the broken links by sending http requests.
# As the first command line argument provide the directory to do the search, 
# if not by default it will be the current working directory.
# In the final report, we consider the links with HTTP status from 200-400 as valid.


# This tool can be used in a terminal or as a GitHub webhook to provide reports.
if [ "$#" -eq 0 ]; then
	echo ""
	echo "Illegal number of command line arguments!"
	echo "Use --help for more information."
	echo ""
	exit
fi


if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "--h" ]; then
	echo ""
	echo "Script for validating links in  Repositories"
	echo "============================================"
	echo ""
	echo "--report <terminal,email> 		Select if you wish the reporting to done on terminal or through e-mails."		 
	echo "--dir <path>				Provide related path of a directory"
	echo "--link <given link>			This option is not allowed if a --dir i given."
	echo "--repository <repo's link> 		Provide the link of the repo to be analyzed."
	echo "--debug					Enable debug mode (printing messages)"
	echo ""
	exit
fi

# Retrieve all command line arguments

# Get all arguments
args=("$@") 

# Get number of elements 
ELEMENTS=${#args[@]} 

# Initiallize parameters
report="0"
debugging="0"
LINK="0"
DIR="0"
REPO="0"

STATUS_SUCCESS=0
STATUS_REDIRECT=0
STATUS_CLIENT_ERROR=0
STATUS_SERVER_ERROR=0

# echo each element in array  
# for lQsds
for (( i=0;i<$ELEMENTS;++i)); do  

	case "${args[${i}]}" in 
	("--report") report=${args[i+1]} ;;
	("--dir") DIR=${args[i+1]} ;;
	("--link") LINK=${args[i+1]} ;;
	("--repository") REPO=${args[i+1]} ;;
	("--debug") debugging="1" ;;
	esac
done

if [ "$report" != "terminal" ] && [ "$report" != "email" ]; then
	echo ""
	echo -e "\e[41mWrong\e[49m command line parameters, please revise and execute again."
	echo ""
	exit
fi

# If both LINK and DIR are give the count it as error
if [ "$LINK" != "0" ] && [ "$DIR" != "0" ] && ["$REPO" != "0" ]; then
	echo "You  are not allowed to give a --dir, --link, and --repository options at the same time, please try again"
	exit
fi


# Create tmp directories to store results which later on will be push as an email notifications to the user
if [ "$report" = "email" ]; then
	rm -rf tmp
	mkdir tmp
fi

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
			echo "=====================================================================" 
			echo Directory: $1/$i
			traverse "$1/$i" `expr $2 + 1`
		else
			echo "---------------------------------------------------------------------" 
			echo File: $1/$i 
			# Calling function to check the status of the $i file's link 
			if [ "$report" = "email" ]; then
				getLinkStatus $1/$i >> tmp/1.txt
			else
				getLinkStatus $1/$i
			fi
		fi
	done< <(ls "$1")
}

function printForTerminal {
	GETSTATUS=$(echo $1 | awk -F "|" '{print $2}')
	GETLINK=$(echo $1 | awk -F "|" '{print $3}')

	# Adding the color for invisible mode to make an awesome printing
 	if [ ! -z $GETSTATUS ]; then 
		if [ $GETSTATUS -lt 300 ]; then
			echo -e "|-\e[42m$GETSTATUS\e[49m-| $GETLINK"	
		elif [ $GETSTATUS -lt 400 ]; then
			echo -e "|-\e[43m$GETSTATUS\e[49m-| $GETLINK"	
		elif [ $GETSTATUS -lt 500 ]; then
			echo -e "|-\e[41m$GETSTATUS\e[49m-| $GETLINK"
		elif [ $GETSTATUS -lt 600 ]; then
			echo -e "|-\e[45m$GETSTATUS\e[49m-| $GETLINK"
		else
			echo "Unknow option..."
		fi
	fi
}

function getLinkStatus {

while read LINE; do
   URL=$(curl -o /dev/null --silent --head --write-out "|%{http_code}| $LINE\n" "$LINE")
   
   if [ "$report" == "terminal" ]; then
	printForTerminal "$URL"
   else
   	echo $URL
   fi
   increaseStatus $URL
done< <(egrep -ro 'https?://[^ ]+' $1 | sort | awk -F ":" '{print $1":"$2}' | tr -d '}*' | tr -d ',' | tr -d '"' | tr -d ')' | tr -d '(' | tr -d ';' | sed 's/\.$//' | sed 's/>.*//' | uniq )
}

function increaseStatus {

	STATUS=$(echo $1 | awk -F "|" '{print $2}')
	
	if [ ! -z $STATUS ]; then 
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
	fi
}

function getLinksFromLink { 

while  read LINE; do
	URL=$(curl -s -r /dev/null --silent --head --write-out "|%{http_code}| $LINE\n" "$LINE" --output /dev/null)
	if [ "$report" == "terminal" ]; then
        	printForTerminal "$URL"
   	else
        	echo $URL >> tmp/1.txt
   	fi
   	increaseStatus $URL
done< <(lynx -dump $1 | grep -A999 "^References$" | tail -n +3 | awk '{print $2 }')

}


function getRepoLinks {
	
	REPO=$1

	# If the user gave / ending then remove it
	if [[ "$REPO" =~ '/'$ ]]; then
        	REPO=$(echo $REPO | sed 's/\/$//g')
	fi

	# If a user gave .git ending then remove it
	if [[ "$REPO" =~ '.git'$ ]]; then
        	REPO=$(echo $REPO | sed 's/\.git$//g')
	fi

	#Clone repo and mv it in a temp file, that is cloned_repo
	if [ -d "cloned_repo" ]; then
        	rm -rf cloned_repo
        	mkdir cloned_repo
	fi

	source "spinner.sh"
	start_spinner 'Cloning repository...'
	git clone $REPO
	stop_spinner $?

	REPO_NAME=$(echo $REPO | awk -F"/" '{print $5}')
	mv $REPO_NAME cloned_repo

	#Now set DIR equal to REPO and threat is a DIR
	DIR=cloned_repo/$REPO_NAME
	# Now call the traverse function as used for normal directories
	#if [ "$report" == "email" ]; then
        #	traverse cloned_repo/$REPO_NAME 0 >> tmp/1.txt
        #else
         #      	traverse cloned_repo/$REPO_NAME 0
       	#fi


}

function printReports {

	# Calculating total link's validity
	TOTAL=$((STATUS_SUCCESS+STATUS_REDIRECT+STATUS_CLIENT_ERROR+STATUS_SERVER_CLIENT))
	TOTAL_VALIDITY=$(echo "scale=2; ((($STATUS_SUCCESS + $STATUS_REDIRECT)) / $TOTAL) * 100" | bc)
	
	echo ""
	echo "Preparing reports"
	echo "Total link's STATUS"
	echo "===================" 
	if [ "$report" == "terminal" ]; then
		echo -e "\e[42m$STATUS_SUCCESS\e[49m Success links" 
		echo -e "\e[43m$STATUS_REDIRECT\e[49m Redirection links" 
		echo -e "\e[41m$STATUS_CLIENT_ERROR\e[49m Client error links" 
		echo -e "\e[45m$STATUS_SERVER_ERROR\e[49m Server error links"
		echo "Total link's validity: $TOTAL_VALIDITY%"
	else
		echo "$STATUS_SUCCESS Success links" 
		echo "$STATUS_REDIRECT Redirection links" 
		echo "$STATUS_CLIENT_ERROR Client error links" 
		echo "$STATUS_SERVER_ERROR Server error links"
		echo "Total link's validity: $TOTAL_VALIDITY%"
	fi
	
	if [ "$report" =  "email" ]; then
		echo " " 
		echo "[Logs] Detailed report" 
		echo "======================"
	fi 
}

# If link is given instead of dir then call getLinksFromLink function
if [ "$LINK" != "0" ]; then
	getLinksFromLink $LINK
fi

# If repository option is provided then act accordingly
if [ "$REPO" != "0" ]; then
	getRepoLinks $REPO
fi

#if [[ -z "$DIR" ]] && [[ "$LINK" == "0" ]] ; then
if [ "$DIR" != "0" ]; then 
	if [ -z "$DIR" ]; then
		if [ "$report" == "email" ]; then
			traverse . 0 >> tmp/1.txt
		else
			traverse . 0 
		fi
	else
		if [ "$report" == "email" ]; then
			traverse $DIR 0 >> tmp/1.txt
		else
			traverse $DIR 0 
		fi
	fi
fi

if [ "$report" == "email" ]; then
	printReports >> tmp/top.txt
	cat tmp/1.txt >> tmp/top.txt
	mail -s "[LinksValidator] Status Report" sgeorgiou@aueb.gr < tmp/top.txt
else	
	printReports
fi
exit
