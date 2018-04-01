#!/bin/bash

# This script will receive as an input a link from GitHub, will clone it and then it will call the linksValidatio.sh script

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
        echo "Script for alayzing if links are valid in a Repositories"
        echo "========================================================"
        echo ""
        echo "--repository <link>		Give the repositories link to analyze"
        echo "--debug                           Enable debug mode (printing messages)"
        echo ""
        exit
fi

# Retrieve all command line arguments

# Get all arguments
args=("$@")

# Get number of elements
ELEMENTS=${#args[@]}

# Initiallize parameters
REPO="0"
debugging="0"

# echo each element in array
# for lQsds
for (( i=0;i<$ELEMENTS;++i)); do

        case "${args[${i}]}" in
        ("--repository") REPO=${args[i+1]} ;;
        esac
done


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

# Using validate_all.sh to get the status of the repository
bash validate_all.sh --report terminal --dir cloned_repo/$REPO_NAME
