#!/bin/bash

name_file="/home/ishmael/.sbar/.name"
batcapfile="/sys/class/power_supply/BAT0/capacity"
batsymfile="/home/ishmael/.sbar/.batsym"

# -------------------------------
# Set time, get ready to update

while true; do
	bardate=$(date +'%m-%d-%y')
	bartime=$(date +'%R')

	batsym=$(cat $batsymfile) 
	bat=$(cat $batcapfile)

	# Update network status
	/ibin/sbar_network.sh

	# Update date and time
	/ibin/sbar_update.sh "$(sed "s/\S\+/$bardate/12" "$name_file")"
	/ibin/sbar_update.sh "$(sed "s/\S\+/$bartime/13" "$name_file")"

	# Update battery - status will update whenever it changes
	/ibin/sbar_update.sh "$(sed "s/\S\+/$batsym/9" "$name_file")"
	/ibin/sbar_update.sh "$(sed "s/\S\+/$bat%/10" "$name_file")"
done
