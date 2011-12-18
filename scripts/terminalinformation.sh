#!/bin/bash

#
# Print information to the terminal when we launch a terminal session from MacHg
#
macHgNoColor='\033[0m'
macHgRedColor='\033[0;31m'
macHgBlueColor='\033[0;34m'
clear
/usr/bin/osascript > /dev/null 2>&1 << EOF
tell application "Terminal"
	activate
end tell
tell application "System Events"
	click menu item "Clear Scrollback" in menu "View" of menu bar item "View" in menu bar 1 of process "Terminal"
end tell
EOF
echo -e "Changed directory to: ${macHgRedColor}`pwd`${macHgNoColor}"
echo -e "${macHgBlueColor}$1${macHgNoColor} and ${macHgBlueColor}$2${macHgNoColor} are aliased to MacHg's mercurial binary. See http://preview.tinyurl.com/67fpjc3"
#echo -ne "Changed directory to: \[\033[0;31m\]`pwd`"
