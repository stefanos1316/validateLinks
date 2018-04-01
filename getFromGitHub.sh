#!/bin/bash

# This script will receive as an input a link from GitHub, will clone it and then it will call the linksValidatio.sh script

REPO=$1

# If the user gave / ending then remove it
if [[ "$REPO" =~ '/'$ ]]; then 
	REPO=$(echo $REPO | sed 's/\/$//g')
fi

#Clone repo and mv it in a temp file, that is cloned_repo
if [ -d "cloned_repo" ]; then
	rm -rf cloned_repo
	mkdir cloned_repo
fi

source "spinner.sh"
start_spinner 'Cloning repository...'
git clone $1
stop_spinner $?

REPO_NAME=$(echo $1 | awk -F"/" '{print $5}')
mv $REPO_NAME cloned_repo

# Using validate_all.sh to get the status of the repository
bash validate_all.sh --report terminal --dir cloned_repo/$REPO_NAME
