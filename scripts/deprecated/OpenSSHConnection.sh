#!/bin/bash

# TurnProxyOn.sh
# Tunnl
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

SSHLOG=/tmp/sidestepssh.log

ssh -D 9050 -N -v chetan@polluxapp.com 2> $SSHLOG