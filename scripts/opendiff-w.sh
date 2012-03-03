#!/bin/sh
# opendiff returns immediately, without waiting for FileMerge to exit.
# Piping the output makes opendiff wait for FileMerge.
OPENDIFF=/Applications/Xcode.app/Contents/Developer/usr/bin/opendiff
if [ ! -f "$OPENDIFF" ]; then
	OPENDIFF=/usr/bin/opendiff
	if [ ! -f "$OPENDIFF" ]; then
		OPENDIFF=/Developer/usr/bin/opendiff
		if [ ! -f "$OPENDIFF" ]; then
			echo "MacHg can't find either /Applications/Xcode.app/Contents/Developer/usr/bin/opendiff or /usr/bin/opendiff or /Developer/usr/bin/opendiff " 1>&2
			exit 2
		fi
	fi
fi
"$OPENDIFF" "$@" | cat