#!/bin/bash

# Action		muted			+/- as $1, $2 is the percent amount
[[ "$1" = "mute" ]] && amixer set Master mute || amixer set Master "$2"%"$1" unmute

# Status		muted			already has % symbol
[[ "$1" = "mute" ]] && vol="X" || vol=$(amixer get Master | awk -F"[][]" '/dB/ { print $2 }')

#"VOL: $vol | o $bright% | $netname | $batsym $bat% | $bardate $bartime"
/ibin/sbar_update.sh "$vol" 2
