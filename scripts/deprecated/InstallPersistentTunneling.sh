#!/bin/bash

# InstallPersistentTunnel.sh
# Tunnl
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

# Set paths
SSHCONFIG=~/.ssh/config

# Create .ssh folder if not exists
mkdir -p ~/.ssh

# Create .ssh/config file if not exists
touch $SSHCONFIG

# Add ssh config optiosn
if [ `grep -c "TCPKeepAlive.*[(yes)(YES)]" $SSHCONFIG` -eq 0 ]; then
    echo "TCPKeepAlive yes \n" >> $SSHCONFIG
fi

if [ `grep -c "ServerAliveInterval.*30" $SSHCONFIG` -eq 0 ]; then
    echo "ServerAliveInterval 30\n" >> $SSHCONFIG
fi