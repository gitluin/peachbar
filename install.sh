#!/bin/sh

# TODO: dependency checks
# Current dependencies:
#	lemonbar-xft
#	GNU coreutils (mostly for GNU sed at the moment)
#	bash (for loops)

test -z "$1" && echo "Please provide your HOME directory as an argument" && exit -1

test -z "$(pwd | grep peachbar)" && echo "Please run this script from the repo directory" && exit -1

BINDIR="/usr/local/bin"


# Trim any trailing / from $1
FINCHAR="$(echo $1 | sed 's/.*\(.\)$/\1/')"
test "$FINCHAR" = "/" && HDIR="$(echo $1 | sed 's/\(.*\).$/\1/')" || \
	HDIR="$1"
CONFDIR="$HDIR/.config/peachbar/"


# ------------------------------------------
# Install .sh files
# ------------------------------------------

SCRIPTFILES="$(ls | grep '.sh')"

echo "Installing peachbar scripts in $BINDIR..."
for SCRIPT in $SCRIPTFILES; do
	test $SCRIPT = "install.sh" && continue
	test $SCRIPT = "uninstall.sh" && continue
	cp "$SCRIPT" "$BINDIR"
done


# ------------------------------------------
# Install .conf files
# ------------------------------------------

echo "Install config files? Will overwrite preexisting config files. [y/n]" && read ANSWER

if test -z "$ANSWER"; then
	echo "Please provide an answer. Exiting..."
	exit 0

elif test "$ANSWER" = "Y" -o "$ANSWER" = "y"; then
	CONFFILES="$(ls | grep '.conf')"

	echo "Creating $CONFDIR..."
	mkdir -p "$CONFDIR"

	echo "Installing .conf files in $CONFDIR..."
	for CONF in $CONFFILES; do
		install -m 666 $CONF "$CONFDIR"
	done
else
	echo "Skipping config install..."
fi


# ------------------------------------------
# Build and install peachbar-timer
# ------------------------------------------

echo "Building and installing utilities..."
cd "./utils/"

make install clean 

echo "Done!"
