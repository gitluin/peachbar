#!/bin/bash

INFF="/tmp/peachbar.fifo"


# ------------------------------------------
# Graphical options
# ------------------------------------------
FDELIM=""
SDELIM=" | "
LDELIM=""


# ------------------------------------------
# "Define" necessary files for your modules
# ------------------------------------------
BATSTATFILE="/sys/class/power_supply/BAT0/status"
BATCAPFILE="/sys/class/power_supply/BAT0/capacity"
NETFILE="/sys/class/net/wlp2s0/operstate"


# ------------------------------------------
# Modules
# ------------------------------------------
Audio() {
	VOL="$(amixer get Master | awk -F"[][]" '/dB/ { print $2 }')"
	echo "VOL: $VOL"
}

Battery() {
	BATSTAT="$(cat $BATSTATFILE)"
	BAT="$(cat $BATCAPFILE)"

	test $BAT -gt 100 && BAT=100

	BATSYM="BAT:"
	test "$BATSTAT" = "Charging" || test "$BATSTAT" = "Unknown" && BATSYM="CHR:"
	test "$BATSTAT" = "Full" && BATSYM="CHR:"

	echo "$BATSYM $BAT%"
}

Brightness() {
	BRIGHT="$(light -G | sed 's/\..*//g')"

	echo "o $BRIGHT%"
}

Network() {
	NETSTATE="$(cat $NETFILE)"

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

	echo "$NETNAME"
}


# ------------------------------------------
# "Draw" a module
# ------------------------------------------
# TODO: properly allows for all delims?
# Does not allow for different FDELIM
#	and splitting delims
DrawModule() {
	echo "$FDELIM$1$SDELIM"
}


# ------------------------------------------
# Pick your modules!
# ------------------------------------------
MODULES="Audio Brightness Network Battery"


# ------------------------------------------
# Initialize
# ------------------------------------------
test "$(pgrep -c "peachbar.sh")" -ge 1 && exit 0

# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"


# ------------------------------------------
# Main loop
# ------------------------------------------
# Sleep until 2s up or signal received
# Useful for updating audio/brightness immediately
trap 'continue' SIGUSR1
while true; do
	STATUSLINE=""

	for MODULE in $MODULES; do
		STATUSLINE="$(echo '$STATUSLINE$($MODULE | DrawModule)')"
	done
	STATUSLINE="$(echo $STATUSLINE$LDELIM)"

	# Write STATUSLINE to FIFO
	echo "$STATUSLINE" > "$INFF"
	
	sleep 2 &
	wait $!
done
