#!/bin/bash

if test -f "$HOME/.config/peachbar/peachbar.conf"; then
	. "$HOME/.config/peachbar/peachbar.conf"
else
	echo "Missing config file at $HOME/.config/peachbar/peachbar.conf"
	exit -1
fi

# TODO:
#	1. Signal with SIGUSR2 to reload config?
#	2. Be able to restart peachbar without killing sara?


# ------------------------------------------
# Parse sara output
# ------------------------------------------
# TODO: TAGS spacing does not look okay with arbitrary tags! Need to standardize.
#	1. Determine which tag has the most characters
#	2. Give that one 2 spaces of padding
#	3. Add the difference to everyone else
#		a. What about odd numbers?
ParseSara() {
	LTBUTTONSTART="%{A:sarasock 'setlayout tile':}%{A3:sarasock 'setlayout monocle':}"
	LTBUTTONEND="%{A}%{A}"

	# Pass MONLINE, TAGS
	MONLINE="$1"
	TAGS="$2"

	TAGSTR="%{B$INFOBG}"

	# MonNum:OccupiedDesks:SelectedDesks:LayoutSymbol
	# 0:000000000:000000000:[]= -> 000000000:000000000:[]=
	MONLINE="$(echo $MONLINE | cut -d':' -f2-4)"
	ISDESKOCC="$(echo $MONLINE | cut -d':' -f1)"
	ISDESKSEL="$(echo $MONLINE | cut -d':' -f2)"
	LAYOUTSYM="$(echo $MONLINE | cut -d':' -f3)"

	# TODO: is ${#STRING} portable?
	# TODO: options for all tags or just occupied
	for (( i=0; i<${#ISDESKOCC}; i++ )); do
		TAGBUTTONSTART="%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}"
		TAGBUTTONEND="%{A}%{A}"

		if test "$(echo $ISDESKSEL | cut -c$((i + 1)))" -eq 1; then
			TMPFG=$SELCOLFG
			TMPBG=$SELCOLBG
		elif test "$(echo $ISDESKOCC | cut -c$((i + 1)))" -eq 1; then
			TMPFG=$OCCCOLFG
			TMPBG=$OCCCOLBG
		else
			TMPFG=$INFOFG
			TMPBG=$INFOBG
		fi

		TAGSTR="${TAGSTR}%{F$TMPFG}%{B$TMPBG}${TAGBUTTONSTART}   $(echo $TAGS | cut -d':' -f$((i + 1)) )   ${TAGBUTTONEND}%{B$INFOBG}%{F$INFOFG}"
	done
	TAGSTR="${TAGSTR}${LTBUTTONSTART}  $LAYOUTSYM  ${LTBUTTONEND}%{B-}"

	echo "${TAGSTR}"
}


# ------------------------------------------
# Initialization
# ------------------------------------------

# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"

peachbar.sh &


# ------------------------------------------
# Main loop
# ------------------------------------------
while read line; do
	MULTI=$(xrandr -q | grep "$EXTDIS" | awk -F" " '{ print $2 }')

	# TODO: jank. denote the start of sara info somehow.
	# if line is sara info
	if [[ "${line:0:1}" =~ ^[0-4].* ]]; then
		# monitor 0 (lemonbar says it's 1)
		MONLINE0="$(cut -d' ' -f1 <<<"$line")"
		TAGSTR0="$(ParseSara $MONLINE0 $TAGS)"

		if [ "$MULTI" = "connected" ]; then
			# monitor 1 (lemonbar says it's 0)
			MONLINE1="$(cut -d' ' -f2 <<<"$line")"
			TAGSTR1="$(ParseSara $MONLINE1 $TAGS)"
		fi
	# else, line is peachbar info
	else
		BARSTATS="$line"
	fi

	if [ "$MULTI" = "connected" ]; then
		printf "%s\n" "%{S0}%{l}${TAGSTR1}%{r}$BARSTATS%{S1}%{l}${TAGSTR0}%{r}$BARSTATS"
	else
		printf "%s\n" "%{l}${TAGSTR0}%{r}$BARSTATS"
	fi
done < "$INFF" | lemonbar -a 32 -g x"$BARH"+"$BARX"+"$BARY" -d -f "$BARFONT" -B "$BARBG" -F "$BARFG" | sh &

# Pull information from sara
exec sara > "$INFF"
