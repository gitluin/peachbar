#!/bin/bash

name_file="/home/ishmael/.sbar/.name"
tmp_file="/home/ishmael/.sbar/.tmpname"
sbarname="$(cat $name_file)"
batcapfile="/sys/class/power_supply/BAT0/capacity"
batsymfile="/home/ishmael/.sbar/.batsym"

INFF="/tmp/saralemon.fifo"
[[ -p $INFF ]] || mkfifo -m 600 "$INFF"

# -------------------------------
# Set time, get ready to update

while true; do
	bardate=$(date +'%m-%d-%y')
	bartime=$(date +'%R')

	batsym=$(cat $batsymfile) 
	bat=$(cat $batcapfile)

	# Update network status
	/ibin/sbar_network.sh

	# -------------------------------
	# Update sbar

	# Get current xsetroot name
	# LOCK OR SOMETHING HERE
	exec 9>/tmp/sbarlock
	if ! flock -w 5 9 ; then
		echo "Could not get the lock :("
		exit 1
	fi

	#"VOL: $vol | $brightsym $bright% | $netname | $batsym $bat% | $bardate $bartime"
	sed "s/\S\+/$bardate/12" "$name_file" > "$tmp_file"
	sed "s/\S\+/$bartime/13" "$tmp_file" > "$name_file"

	# Update battery - status will update whenever it changes
	sed "s/\S\+/$batsym/9" "$name_file" > "$tmp_file"
	sed "s/\S\+/$bat%/10" "$tmp_file" > "$name_file"

	cat "$name_file" > "$INFF"

	# RELEASE LOCK
	9>&-
	rm -rf /tmp/sbarlock
	sleep 15
done
