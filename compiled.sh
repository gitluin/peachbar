#!/bin/bash

Audio() {
	# Action		muted			+/- as $1, $2 is the percent amount
	test "$1" = "mute" && amixer set Master mute || amixer set Master "$2"%"$1" unmute

	# Status		muted			already has % symbol
	test "$1" = "mute" && vol="X" || vol=$(amixer get Master | awk -F"[][]" '/dB/ { print $2 }')

	#"VOL: $vol | o $bright% | $netname | $batsym $bat% | $bardate $bartime"
	sbar_update.sh "$vol" 2
}

Bright() {
	# Pass -A (up)/-U (down) as $1, amount as $2
	light "$1" "$2"

	BRIGHT="$(light -G)"
	BRIGHT="${BRIGHT%.*}"

	#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
	sbar_update.sh "$BRIGHT%" 5
}

Battery() {
	BATSTATFILE="/sys/class/power_supply/BAT0/status"
	BATCAPFILE="/sys/class/power_supply/BAT0/capacity"

	# Let udev breathe
	sleep 1

	BATSTAT="$(cat $BATSTATFILE)"
	BAT="$(cat $BATCAPFILE)"

	test $BAT -gt 100 && BAT=100

	BATSYM="BAT:"
	test "$BATSTAT" = "Charging" || test "$BATSTAT" = "Unknown" && BATSYM="CHR:"
	test "$BATSTAT" = "Full" && BATSYM="CHR:"

	#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
	# Sudo is necessary when this is run from udev
	sudo sbar_update.sh "$BATSYM" 9 "$BAT%" 10
}

Network() {
	NETSTATE="$(cat "/sys/class/net/wlp2s0/operstate")"

	if [ $NETSTATE = "up" ]; then
		# bssid comes first, fuhgettaboudit
		WPASTR=($(sudo wpa_cli -i wlp2s0 status | grep ssid))
		NETNAME="${WPASTR[1]}"
		NETNAME="${NETNAME:5}"

		for (( i=2; i<${#WPASTR[@]}; i++)); do
			NETNAME="${NETNAME}_${WPASTR[$i]}"
		done
	else
		NETNAME="down"
	fi

	sbar_update.sh "$NETNAME" 7
}

Update() {
	INFF="/tmp/saralemon.fifo"
	NAMEFILE="/home/ishmael/.sbar/.name"
	TMPFILE="/home/ishmael/.sbar/.tmpname"
	LOCKFILE="/tmp/sbarlock"

	if (( $# % 2 )); then
		echo "Need value-position pairs!"
		exit 1
	fi

	# Get lock
	exec 9>"$LOCKFILE"
	if ! flock -w 5 9 ; then
		echo "Could not get the lock :("
		exit 1
	fi

	FROMFNAME="$NAMEFILE"
	TOFNAME="$TMPFILE"

	# For each pair of arguments, sed the shit out of it
	for (( VAL=1; VAL<$#; VAL=$(( VAL + 2 )) )); do
		POS=$((VAL+1))
		#"VOL: $VOL | o $BRIGHT% | $NETNAME | $BATSYM $BAT% | $BARDATE $BARTIME"
		sed "s/\S\+/${!VAL}/${!POS}" "$FROMFNAME" > "$TOFNAME"
		TMPFNAME="$FROMFNAME"
		FROMFNAME="$TOFNAME"
		TOFNAME="$TMPFNAME"
	done

	# If we ended on $TMPFILE, update $NAMEFILE
	test "$FROMFNAME" = "$TMPFILE" && cat "$TMPFILE" > "$NAMEFILE"

	cat "$NAMEFILE" > "$INFF"

	# Release lock
	9>&-
	rm -rf "$LOCKFILE"
}

Loop() {
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
}
