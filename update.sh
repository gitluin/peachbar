#!/bin/bash

INFF="/tmp/saralemon.fifo"
NAMEFILE="/home/ishmael/.sbar/.name"
TMPFILE="/home/ishmael/.sbar/.tmpname"
LOCKFILE="/tmp/sbarlock"

if (( $# % 2 )); then
	echo "Need value-position pairs!"
	exit 1
fi

# Get lock
exec 9>"$LOCKFILE"
if ! flock -w 5 9 ; then
	echo "Could not get the lock :("
	exit 1
fi

FROMFNAME="$NAMEFILE"
TOFNAME="$TMPFILE"

# For each pair of arguments, sed the shit out of it
for (( VAL=1; VAL<$#; VAL=$(( VAL + 2 )) )); do
	POS=$((VAL+1))
	#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
	sed "s/\S\+/${!VAL}/${!POS}" "$FROMFNAME" > "$TOFNAME"
	TMPFNAME="$FROMFNAME"
	FROMFNAME="$TOFNAME"
	TOFNAME="$TMPFNAME"
done

# If we ended on $TMPFILE, update $NAMEFILE
test "$FROMFNAME" = "$TMPFILE" && cat "$TMPFILE" > "$NAMEFILE"

cat "$NAMEFILE" > "$INFF"

# Release lock
9>&-
rm -rf "$LOCKFILE"
