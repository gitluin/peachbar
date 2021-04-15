#!/bin/sh

# TODO: dependency checks
# Current dependencies:
#	lemonbar-xft
#	GNU coreutils (mostly for GNU sed at the moment)
#	bash (for loops)

test -z "$1" && echo "Please provide your HOME directory as an argument" && exit -1

test -z "$(pwd | grep peachbar)" && echo "Please run this script from the repo directory" && exit -1

SCRIPTDIR="/usr/local/bin"


# Trim any trailing / from $1
FINCHAR="$(echo $1 | sed 's/.*\(.\)$/\1/')"
test "$FINCHAR" = "/" && HDIR="$(echo $1 | sed 's/\(.*\).$/\1/')" || \
	HDIR="$1"
CONFDIR="$HDIR/.config/peachbar/"


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


# ------------------------------------------
# Install battery.rules if desired
# ------------------------------------------

echo "Would you like to install battery.rules? Will skip if it would clobber an existing /etc/udev/battery.rules file. [y/N]" && read ANSWER
if (test "$ANSWER" = "y" || test "$ANSWER" = "Y"); then
	cp peachbar-battery.rules tmp.rules
	sed -i "s/home\/ishmael/$HDIR/" tmp.rules

	echo "Installing battery.rules..."
	test -e /etc/udev/rules.d/battery.rules && \
		echo "Skipping battery.rules installation to avoid clobbering. Recommend manual installation." || \
		cp -n "tmp.rules" /etc/udev/rules.d/battery.rules

	rm tmp.rules

	udevadm control --reload
else
	echo "Skipping battery.rules installation..."
fi

echo "Done!"
