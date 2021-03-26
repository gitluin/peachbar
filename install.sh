#!/bin/sh

test -z "$1" && echo "Please provide your HOME directory as an argument" && exit -1

test -z "$(pwd | grep peachbar)" && echo "Please run this script from the repo directory" && exit -1

SCRIPTDIR="/usr/local/bin"
CONFDIR="$1/.config/peachbar/"

# TODO:
# Trim any trailing / from $1
# Install battery.rules
#	Prompt user for username under which to do this


# ------------------------------------------
# Install .sh files
# ------------------------------------------

SCRIPTFILES="$(ls | grep '.sh')"

echo "Installing peachbar scripts in $SCRIPTDIR..."
for SCRIPT in $SCRIPTFILES; do
	test $SCRIPT = "install.sh" && continue
	test $SCRIPT = "uninstall.sh" && continue
	cp "$SCRIPT" "$SCRIPTDIR"
done


# ------------------------------------------
# Install .conf files
# ------------------------------------------

# TODO: prompt user to overwrite existing files

CONFFILES="$(ls | grep '.conf')"

echo "Creating $CONFDIR..."
mkdir -p "$CONFDIR"

# TODO: file permissions
echo "Installing .conf files in $CONFDIR..."
for CONF in $CONFFILES; do
	cp $CONF "$CONFDIR"
done
