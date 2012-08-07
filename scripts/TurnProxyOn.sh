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

SOCKSHOST=`networksetup -getsocksfirewallproxy $DEVICENAME | grep Server | cut -b 9-`
SOCKSPORT=`networksetup -getsocksfirewallproxy $DEVICENAME | grep Port | cut -b 7-`
if [ "$SOCKSHOST" != "127.0.0.1" ] || [ "$SOCKSPORT" != "$LOCALPORT" ]; then
	networksetup -setsocksfirewallproxy $DEVICENAME 127.0.0.1 $LOCALPORT
fi

NETWORKS="*.local localhost 127.0.0.1 169.254/16 192.168/16 172.16.0.0/12 10.0.0.0/8"
CONFNETWORKS=`networksetup -getproxybypassdomains $DEVICENAME | xargs`
if [ "$CONFNETWORKS" != "$NETWORKS" ]; then
	networksetup -setproxybypassdomains $DEVICENAME $NETWORKS
fi

networksetup -setsocksfirewallproxystate $DEVICENAME on
