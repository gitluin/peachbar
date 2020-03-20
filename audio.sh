#!/bin/bash

name_file="/home/ishmael/.sbar/.name"

# -------------------------------
# Set volume, get ready to update

# Pass +/- as $1 to do the thing, $2 is the amount
if [ "$1" = "mute" ]; then
	amixer set Master mute
	vol="X"

else
	amixer set Master "$2"%"$1" unmute
	# Skip over the mute symbol
	vol=$(amixer sget Master | awk -F"[][]" '/dB/ { print $2 }')
	vol="${vol::-1}%"
fi 

/ibin/sbar_update.sh "$(sed "s/\S\+/$vol/2" "$name_file")"
