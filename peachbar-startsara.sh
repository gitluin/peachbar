#!/bin/bash

EXTDIS="HDMI-0"


# ------------------------------------------
# Graphical options
# ------------------------------------------

TAGS="123456789"

BARFG="#ffffff"
# From 00 to 99
BARALPHA=85
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
	OCCCOLBG="#4E387E"
	SELCOLBG="#F87217"

	LTBUTTONSTART="%{A:sarasock 'setlayout tile':}%{A3:sarasock 'setlayout monocle':}"
	LTBUTTONEND="%{A}%{A}"

	# TODO: POSIX
	#	sed/cut for substring-ing

	# Pass MONLINE, TAGS
	MONLINE="$1"
	TAGS="$2"

	TAGSTR=""

	# MonNum:OccupiedDesks:SelectedDesks:LayoutSymbol
	# 0:00000000:00000000:[]= -> 00000000:00000000:[]=
	MONLINE="$(cut -d':' -f2-4 <<<"$MONLINE")"
	ISDESKOCC="$(cut -d':' -f1 <<<"$MONLINE")"
	ISDESKSEL="$(cut -d':' -f2 <<<"$MONLINE")"
	LAYOUTSYM="$(cut -d':' -f3 <<<"$MONLINE")"

	# TODO: less messy
	# TODO: options for all tags or just occupied
	for (( i=0; i<${#ISDESKOCC}; i++ )); do
		TAGBUTTONSTART="%{A:sarasock 'view $i':}%{A3:sarasock 'toggleview $i':}"
		TAGBUTTONEND="%{A}%{A}"

		if [ ${ISDESKSEL:$i:1} -eq 1 ]; then
			TMPBG=$SELCOLBG
		elif [ ${ISDESKOCC:$i:1} -eq 1 ]; then
			TMPBG=$OCCCOLBG
		else
			TMPBG=$BARBG
		fi

		TAGSTR="${TAGSTR}%{B$TMPBG}${TAGBUTTONSTART}   ${TAGS:$i:1}   ${TAGBUTTONEND}%{B-}"
	done
	TAGSTR="${TAGSTR}${LTBUTTONSTART}  $LAYOUTSYM  ${LTBUTTONEND}"

	echo "${TAGSTR}"
}


# ------------------------------------------
# Initialization
# ------------------------------------------

INFF="/tmp/peachbar.fifo"
# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"

peachbar.sh "$INFF" &


# ------------------------------------------
# Main loop
# ------------------------------------------
while read line; do
	MULTI=$(xrandr -q | grep "$EXTDIS" | awk -F" " '{ print $2 }')

	# TODO: INFF should only be for sara!
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
