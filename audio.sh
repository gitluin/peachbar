#!/bin/bash

# -------------------------------
# Set volume, get ready to update

# Pass +/- as $1 to do the thing, $2 is the amount
if [ "$1" = "mute" ]; then
	amixer set Master mute
	vol="X"

else
	amixer set Master "$2"%"$1" unmute
	# Skip over the mute symbol
	vol=$(amixer get Master | awk -F"[][]" '/dB/ { print $2 }')
	vol="${vol::-1}%"
fi 

#"VOL: $vol | o $bright% | $netname | $batsym $bat% | $bardate $bartime"
/ibin/sbar_update.sh "$vol" 2
