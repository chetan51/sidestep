#!/bin/bash

# WatchSSHConnectionForChanges
# Sidestep
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

if [ ! $1 ]; then
	echo "Usage: WatchSSHConnectionForChanges sshLogFilePath"
    exit 0
fi

SSHLOG=$1

# Create log file if not exists
touch $SSHLOG

while read line 
do
    if [ ! `echo $line | grep -c 'Entering interactive session'` -eq 0 ]; then
        printf %d 1
        exit 1
    elif [ ! `echo $line | grep -c 'Permission denied ('` -eq 0 ]; then
        printf %d 2
        exit 0
    elif [ ! `echo $line | grep -c 'Could not resolve hostname'` -eq 0 ]; then
        printf %d 3
        exit 0
	elif [ ! `echo $line | grep -c 'Connection to .* timed out'` -eq 0 ]; then
        printf %d 4
        exit 0
    elif [ ! `echo $line | grep -c 'Sidestep: Terminate connection attempt manually'` -eq 0 ]; then
        printf %d 5
        exit 0
    fi
done < <(tail -F $SSHLOG)