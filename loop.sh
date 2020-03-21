#!/bin/bash

BATCAPFILE="/sys/class/power_supply/BAT0/capacity"
BATSYMFILE="/home/ishmael/.sbar/.batsym"

# -------------------------------
# Set time, get ready to update

while true; do
	BARDATE=$(date +'%m-%d-%y')
	BARTIME=$(date +'%R')

	BATSYM=$(cat $BATSYMFILE) 
	BAT=$(cat $BATCAPFILE)

	# Update network status
	/ibin/sbar_network.sh

	#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
	/ibin/sbar_update.sh "$BARDATE" 12 "$BARTIME" 13 "$BATSYM" 9 "$BAT%" 10
	sleep 15
done
