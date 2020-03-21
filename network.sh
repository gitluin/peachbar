#!/bin/bash

netstate=$(cat "/sys/class/net/wlp2s0/operstate")

# -------------------------------
# Set network, get ready to update

if [ $netstate = "up" ]; then
	# bssid comes first, fuhgettaboudit
	netname=($(sudo wpa_cli -i wlp2s0 status | grep ssid))

	outname=${netname[1]}
	outname=${outname:5}
	i=2
	if [ ${#netname[@]} -gt 2 ]; then
		outname="${outname} ${netname[$i]}"

		(( i++ ))
	fi
	netname="$outname"
	netname="${netname// /_}"
else
	netname="down"
fi

/ibin/sbar_update.sh "$netname" 7
