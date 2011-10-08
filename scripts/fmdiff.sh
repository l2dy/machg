#!/bin/sh

#
# Wrapper script to use FileMerge as a diff-cmd in Subversion
#

FM="/Developer/Applications/Utilities/FileMerge.app/Contents/MacOS/FileMerge"

while [ $# != 0 ]; do
	case $1 in
		-u)
			unified=1
		;;
		-L)
			shift
			if [ -z "$leftlabel" ]; then
				leftlabel=$1
			elif [ -z "$rightlabel" ]; then
				rightlabel=$1
			else
				echo "Too many labels" 1>&2
				exit 2
			fi
		;;
		-*)
			echo "Unknown option: $1" 1>&2
			exit 2
		;;
		*)
			if [ -z "$leftfile" ]; then
				leftfile=$1
			elif [ -z "$rightfile" ]; then
				rightfile=$1
			else
				echo "Too many files to diff" 1>&2
				exit 2
			fi
	esac
	shift
done

if [ -z "$leftfile" ] || [ -z "$rightfile" ]; then
	echo "Usage: $0 [options] leftfile rightfile" 1>&2
	exit 2
fi

echo Starting FileMerge... 1>&2
[ -n "$leftlabel"  ] && echo  Left: $leftlabel 1>&2
[ -n "$rightlabel" ] && echo Right: $rightlabel 1>&2
#exec "$FM" -left "$leftfile" -right "$rightfile" -merge $rightfile

# Find the com.apple.TextEncoding extended attributes of the files
leftattributes=`xattr -p com.apple.TextEncoding "$leftfile" 2>/dev/null`
rightattributes=`xattr -p com.apple.TextEncoding "$rightfile" 2>/dev/null`

# if the encodings are not UTF-8, then make them UTF-8
shopt -s nocasematch
if [ -z "$leftattributes" ] || [ "$leftattributes" != "UTF-8;134217984" ]; then
	xattr -w com.apple.TextEncoding "UTF-8;134217984" "$leftfile"
fi
if [ -z "$rightattributes" ] || [ "$rightattributes" != "UTF-8;134217984" ]; then
	xattr -w com.apple.TextEncoding "UTF-8;134217984" "$rightfile"
fi
shopt -u nocasematch

OPENDIFF=/usr/bin/opendiff
if [ ! -f "$OPENDIFF" ]; then
	OPENDIFF=/Developer/usr/bin/opendiff
	if [ ! -f "$OPENDIFF" ]; then
		echo "MacHg can't find either /usr/bin/opendiff or /Developer/usr/bin/opendiff " 1>&2
		exit 2
	fi
fi

exec "$OPENDIFF" "$leftfile" "$rightfile" -merge "$rightfile"
