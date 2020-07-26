#!/bin/bash

INFF="$1"
test -z $INFF && echo "Please provide FIFO as argument" && exit -1


# ------------------------------------------
# Graphical options
# ------------------------------------------
BARFG="#ffffff"
# From 00 to 99
BARALPHA=85
BARBG="#$BARALPHA""000000"

# Audio
MUTEBG="#F70D1A"

# Battery
CHRBG="#348017"
PANICBG="#F70D1A"

# Brightness
BRIGHTBG="#FFA62F"

# Network
DOWNBG="#F70D1A"


# ------------------------------------------
# Modules
# ------------------------------------------

# Define necessary files for your modules
BATSTATFILE="/sys/class/power_supply/BAT0/status"
BATCAPFILE="/sys/class/power_supply/BAT0/capacity"
NETFILE="/sys/class/net/wlp2s0/operstate"

Audio() {
	STATE="$(amixer get Master | awk -F"[][]" '/Left/ { print $4 }')"
	# NO quotes - drop whitespace
	test $STATE = "off" && VOL="OFF " || \
		VOL="$(amixer get Master | grep 'Front Left:' | \
			sed 's/.*[0-9] \[/[/' | \
			sed 's/\] .*/]/' | \
			sed 's/\[//' | \
			sed 's/\]//')"

	test $STATE = "off" && echo "%{B$MUTEBG}  VOL: $VOL  %{B-}" || \
		echo "  VOL: $VOL  "
}

Battery() {
	BATSTAT="$(cat $BATSTATFILE)"
	BAT="$(cat $BATCAPFILE)"

	test $BAT -gt 100 && BAT=100

	BATSYM="BAT:"
	test "$BATSTAT" = "Charging" || test "$BATSTAT" = "Unknown" && BATSYM="CHR:"
	test "$BATSTAT" = "Full" && BATSYM="CHR:"

	if test $BAT -le 10 && test "$BATSYM" = "BAT:"; then
		echo "%{B$PANICBG}  $BATSYM $BAT%  %{B-}"
	else
		test "$BATSYM" = "BAT:" && echo "  $BATSYM $BAT%  " || \
			echo "%{B$CHRBG}  $BATSYM $BAT%  %{B-}%"
	fi
}

Brightness() {
	BRIGHT="$(light -G | sed 's/\..*//g')"

	echo "%{F$BARFG}%{B$BRIGHTBG}  o $BRIGHT%  %{B-}%{F-}"
}

Network() {
	NETSTATE="$(cat $NETFILE)"

	if [ $NETSTATE = "up" ]; then
		# No double quotes to ignore newline
		NETNAME="$(sudo wpa_cli -i wlp2s0 status | grep ssid)"
		NETNAME=$(echo $NETNAME | sed 's/bssid.*ssid/ssid/g' | sed 's/ssid=//g')
		NETNAME="  $NETNAME  "

	else
		NETNAME="%{B$DOWNBG}  down  %{B-}"
	fi

	echo "$NETNAME"
}

Time() {
	DTIME="$(date +'%m/%d/%y %H:%M')"
	echo "  $DTIME  "
}

MODULES="Audio Brightness Network Battery Time"


# ------------------------------------------
# Initialize
# ------------------------------------------
# Kill other peachbar.sh instances
PEACHPIDS="$(pgrep "peachbar.sh")"
for PEACHPID in $PEACHPIDS; do
	! test $PEACHPID = $$ && kill -9 $PEACHPID
done


# ------------------------------------------
# Main loop
# ------------------------------------------
# Sleep until 10s up or signal received
# Useful for updating audio/brightness immediately
trap 'FLAG=false' SIGUSR1
FLAG=true
while true; do
	STATUSLINE=""

	for MODULE in $MODULES; do
		STATUSLINE="$STATUSLINE$($MODULE)"
	done

	# Write STATUSLINE to FIFO
	echo "$STATUSLINE" > "$INFF"
	
	if $FLAG; then
		sleep 10 &
		wait $!
	else
		FLAG=true
	fi
done
