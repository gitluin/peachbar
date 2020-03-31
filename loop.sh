#!/bin/bash

# -------------------------------
# Set time, get ready to update

while true; do
	BARDATE="$(date +'%m-%d-%y')"
	BARTIME="$(date +'%R')"

	sbar_battery.sh
	sbar_network.sh

	#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
	sbar_update.sh "$BARDATE" 12 "$BARTIME" 13
	sleep 15
done
