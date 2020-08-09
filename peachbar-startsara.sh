#!/bin/bash

EXTDIS="HDMI-0"

# TODO:
#	1. Config file in .config/peachbar/peachbarrc
#		a. Backup scheme in case no config
#	2. Signal with SIGUSR2 to reload config?
#	3. Be able to restart peachbar without killing sara


# ------------------------------------------
# Graphical options
# ------------------------------------------

# TODO: will the spacing look okay?
TAGS="I:II:III:IV:V:VI:VII:VIII:IX"

BARFG="#ffffff"
# From 00 to 99
INFOALPHA=85
BARALPHA=00
INFOBG="#$INFOALPHA""000000"
BARBG="#$BARALPHA""000000"

BARFONT="Noto Sans:size=10"

# Dimensions
# Make sure to adjust for BARH if you put the bar on the bottom!
#	(i.e. y_orig = 1080-18)
BARH=18
BARX=0
BARY=0


# ------------------------------------------
# Parse sara output
# ------------------------------------------
ParseSara() {
	#OCCCOLBG="#4E387E"
	#SELCOLBG="#F87217"
	OCCCOLBG="#FBF6D9"
	SELCOLBG="#2B65EC"

	LTBUTTONSTART="%{A:sarasock 'setlayout tile':}%{A3:sarasock 'setlayout monocle':}"
	LTBUTTONEND="%{A}%{A}"

	# Pass MONLINE, TAGS
	MONLINE="$1"
	TAGS="$2"

	TAGSTR="%{B$INFOBG}"

	# MonNum:OccupiedDesks:SelectedDesks:LayoutSymbol
	# 0:00000000:00000000:[]= -> 00000000:00000000:[]=
	MONLINE="$(echo $MONLINE | cut -d':' -f2-4)"
	ISDESKOCC="$(echo $MONLINE | cut -d':' -f1)"
	ISDESKSEL="$(echo $MONLINE | cut -d':' -f2)"
	LAYOUTSYM="$(echo $MONLINE | cut -d':' -f3)"

	# TODO: is ${#STRING} portable?
	# TODO: options for all tags or just occupied
	for (( i=0; i<${#ISDESKOCC}; i++ )); do
		TAGBUTTONSTART="%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}"
		TAGBUTTONEND="%{A}%{A}"

		if test "$(echo $ISDESKSEL | cut -c$i)" -eq 1; then
			TMPBG=$SELCOLBG
		elif test "$(echo $ISDESKOCC | cut -c$i)" -eq 1; then
			TMPBG=$OCCCOLBG
		else
			TMPBG=$BARBG
		fi

		TAGSTR="${TAGSTR}%{B$TMPBG}${TAGBUTTONSTART}   $(echo $TAGS | cut -d':' -f$i)   ${TAGBUTTONEND}%{B$INFOBG}"
	done
	TAGSTR="${TAGSTR}${LTBUTTONSTART}  $LAYOUTSYM  ${LTBUTTONEND}%{B-}"

	echo "${TAGSTR}"
}


# ------------------------------------------
# Initialization
# ------------------------------------------

INFF="/tmp/peachbar.fifo"
# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"

# TODO: peachbar-start.sh necessary?
peachbar-start.sh "$INFF" &


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
