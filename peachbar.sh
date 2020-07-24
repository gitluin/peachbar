#!/bin/bash


INFF="/tmp/peachbar.fifo"


# ------------------------------------------
# Graphical options
# ------------------------------------------
BEGINDELIM=""
STARTDELIM=""
STOPDELIM=" | "
ENDDELIM=""


# ------------------------------------------
# Define necessary files for your modules
# ------------------------------------------
BATSTATFILE="/sys/class/power_supply/BAT0/status"
BATCAPFILE="/sys/class/power_supply/BAT0/capacity"
NETFILE="/sys/class/net/wlp2s0/operstate"


# ------------------------------------------
# Modules
# ------------------------------------------
Audio() {
	STATE="$(amixer get Master | awk -F"[][]" '/Left/ { print $4 }')"
	# NO quotes - drop whitespace
	test $STATE = "off" && VOL="X" || \
		VOL="$(amixer get Master | awk -F"[][]" '/Left/ { print $2 }')"

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
		# No double quotes to ignore newline
		NETNAME="$(sudo wpa_cli -i wlp2s0 status | grep ssid)"
		NETNAME=$(echo $NETNAME | sed 's/bssid.*ssid/ssid/g' | sed 's/ssid=//g')

	else
		NETNAME="down"
	fi

	echo $NETNAME
}


# ------------------------------------------
# "Draw" a module
# ------------------------------------------
DrawModule() {
	echo "$STARTDELIM$1$STOPDELIM"
}


# ------------------------------------------
# Pick your modules!
# ------------------------------------------
MODULES="Audio Brightness Network Battery"


# ------------------------------------------
# Initialize
# ------------------------------------------
# Kill other peachbar.sh instances
PEACHPIDS="$(pgrep "peachbar.sh")"
for PEACHPID in $PEACHPIDS; do
	! test $PEACHPID = $$ && kill -9 $PEACHPID
done

# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"


# ------------------------------------------
# Main loop
# ------------------------------------------
# Sleep until 10s up or signal received
# Useful for updating audio/brightness immediately
trap 'FLAG=false' SIGUSR1
FLAG=true
while true; do
	STATUSLINE="$BEGINDELIM"

	for MODULE in $MODULES; do
		TOADD="$(DrawModule "$($MODULE)")"
		STATUSLINE="$STATUSLINE$TOADD"
	done
	STATUSLINE=$(echo "$STATUSLINE" | sed "s/$STOPDELIM$//g")
	STATUSLINE="$(echo $STATUSLINE$ENDDELIM)"

	# Write STATUSLINE to FIFO
	echo "$STATUSLINE" > "$INFF"
	
	if $FLAG; then
		sleep 10 &
		wait $!
	else
		FLAG=true
	fi
done
