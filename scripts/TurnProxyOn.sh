#!/bin/bash

# TurnProxyOn.sh
# Sidestep
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

if [ ! $1 ]; then
	echo "Usage: TurnProxyOn localPort"
    exit 0
fi

LOCALPORT=$1

networksetup -setsocksfirewallproxy Airport 127.0.0.1 $LOCALPORT
networksetup -setsocksfirewallproxystate Airport on