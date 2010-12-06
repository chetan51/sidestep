#!/bin/bash

# TurnProxyOn.sh
# Sidestep
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

if [ ! $1 ] || [ ! $2 ]; then
	echo "Usage: TurnProxyOn deviceName localPort"
    exit 0
fi

DEVICENAME=$1
LOCALPORT=$2

networksetup -setsocksfirewallproxy $DEVICENAME 127.0.0.1 $LOCALPORT
networksetup -setsocksfirewallproxystate $DEVICENAME on