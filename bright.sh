#!/bin/bash

# -------------------------------
# Set brightness, get ready to update

# Pass A/U to do the thing
	# up/down
light "$1" "$2"

# Get brightness
BRIGHT=$(light -G)
BRIGHT=${BRIGHT%.*}

#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
/ibin/sbar_update.sh "$BRIGHT%" 5
