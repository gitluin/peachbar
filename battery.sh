#!/bin/bash

name_file="/home/ishmael/.sbar/.name"
batcapfile="/sys/class/power_supply/BAT0/capacity"
batstatfile="/sys/class/power_supply/BAT0/status"
batsymfile="/home/ishmael/.sbar/.batsym"

# -------------------------------
# Set battery, get ready to update

sleep 1

batstat=$(cat $batstatfile) 
bat=$(cat $batcapfile)
if [ "$batstat" = "Charging" ]; then
	batsym="CHR:"
elif [ "$batstat" = "Unknown" ]; then
	batsym="CHR:"
else 
	batsym="BAT:"
fi
echo "$batsym" > "$batsymfile"

#"VOL: $vol | $brightsym $bright% | $netname | $batsym $bat% | $bardate $bartime"
/ibin/sbar_update.sh "$(sed "s/\S\+/$batsym/9" "$name_file")"
/ibin/sbar_update.sh "$(sed "s/\S\+/$bat%/10" "$name_file")"
