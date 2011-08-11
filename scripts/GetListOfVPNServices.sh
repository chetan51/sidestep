#!/bin/bash

# GetListOfVPNServices.sh
# Sidestep
#
# Created by Chetan Surpur on 10/26/10.
# Copyright 2010 Chetan Surpur. All rights reserved.

# redirect stdin
exec <"$0" || exit

# find the start of the AppleScript
found=0
while read v; do
        case "$v" in --*)
                # file offset at start of AppleScript
                found=1; break
                ;;
        esac
done

case "$found" in
    0)  
        echo 'AppleScript not found' >&2
        exit 128
        ;;
esac

# run the AppleScript
bash -c "/usr/bin/osascript"; exit

-- AppleScript starts here

set vpn_services to {}

tell application "System Events"
	tell current location of network preferences
		repeat with s in services
			-- if kind of service = 14, 11, 10, 12, 15 then vpn
			if kind of s is 14 or kind of s is 11 or kind of s is 10 or kind of s is 12 or kind of s is 15 then
				copy name of s to end of my vpn_services
			end if
		end repeat
	end tell
end tell

return vpn_services