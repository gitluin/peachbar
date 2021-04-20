#!/bin/sh

test -z "$1" && echo "Please provide your HOME directory as an argument" && exit -1

SCRIPTDIR="/usr/local/bin"

# Trim any trailing / from $1
FINCHAR="$(echo $1 | sed 's/.*\(.\)$/\1/')"
test "$FINCHAR" = "/" && HDIR="$(echo $1 | sed 's/\(.*\).$/\1/')" || \
	HDIR="$1"
CONFDIR="$HDIR/.config/peachbar/"


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

echo "Would you like to remove your config files as well? [y/N]" && read ANSWER

if test "$ANSWER" = "Y" -o "$ANSWER" = "y"; then
	echo "Removing $CONFDIR..."
	rm -r "$CONFDIR"
else
	echo "Leaving config files intact..."
fi

echo "Done!"
