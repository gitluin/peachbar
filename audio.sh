#!/bin/bash

# Action		muted			+/- as $1, $2 is the percent amount
test "$1" = "mute" && amixer set Master mute || amixer set Master "$2"%"$1" unmute

# Status		muted			already has % symbol
test "$1" = "mute" && vol="X" || vol=$(amixer get Master | awk -F"[][]" '/dB/ { print $2 }')

#"VOL: $vol | o $bright% | $netname | $batsym $bat% | $bardate $bartime"
sbar_update.sh "$vol" 2
