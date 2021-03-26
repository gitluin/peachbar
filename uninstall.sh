#!/bin/sh

test -z "$1" && echo "Please provide your HOME directory as an argument" && exit -1

SCRIPTDIR="/usr/local/bin"
CONFDIR="$1/.config/peachbar/"


# ------------------------------------------
# Delete .sh files
# ------------------------------------------

TODEL="$(ls $SCRIPTDIR | grep 'peachbar')"

echo "Removing peachbar scripts from $SCRIPTDIR..."
for SCRIPT in $TODEL; do
	rm "$SCRIPTDIR/$SCRIPT"
done


# ------------------------------------------
# Delete .config folder
# ------------------------------------------

# TODO: ask before removing CONFDIR

echo "Removing $CONFDIR..."
rm -r "$CONFDIR"
