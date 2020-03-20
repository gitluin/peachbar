#!/bin/bash

name_file="/home/ishmael/.sbar/.name"
tmp_file="/home/ishmael/.sbar/.tmpname"

INFF="/tmp/saralemon.fifo"
[[ -p $INFF ]] || mkfifo -m 600 "$INFF"

# -------------------------------
# Update sbar

# Get current xsetroot name
# LOCK OR SOMETHING HERE
exec 9>/tmp/sbarlock
if ! flock -w 5 9 ; then
	echo "Could not get the lock :("
	exit 1
fi

#"VOL: $vol | $brightsym $bright% | $netname | $batsym $bat% | $bardate $bartime"
echo "$1" > "$tmp_file"
cat "$tmp_file" > "$name_file"
cat $name_file > "$INFF"

# RELEASE LOCK
9>&-
rm -rf /tmp/sbarlock
