#!/bin/bash

# TurnProxyOff.sh
# Sidestep
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

if [ ! $1 ]; then
	echo "Usage: TurnProxyOff.sh deviceName"
    exit 0
fi

DEVICENAME=$1

networksetup -setsocksfirewallproxystate $DEVICENAME off