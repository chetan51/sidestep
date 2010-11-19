#!/bin/bash

# TurnProxyOn.sh
# Tunnl
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

while read line 
do
    if [ ! `echo $line | grep -c 'launchd'` -eq 0 ]; then
        echo 'launchd message'
        exit 0
    fi
done < <(tail -F -n0 /private/var/log/system.log)