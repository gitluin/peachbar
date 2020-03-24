#!/bin/bash

BATCAPFILE="/sys/class/power_supply/BAT0/capacity"
BATSTATFILE="/sys/class/power_supply/BAT0/status"
BATSYMFILE=~/.sbar/.batsym

# Let me breathe
sleep 1

BATSTAT="$(cat $BATSTATFILE)"
BAT="$(cat $BATCAPFILE)"

[[ "$BATSTAT" = "Charging" ]] || [[ "$BATSTAT" = "Unknown" ]] && BATSYM="CHR:" || BATSYM="BAT:"

echo "$BATSYM" > "$BATSYMFILE"

#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
/ibin/sbar_update.sh "$BATSYM" 9 "$BAT%" 10
