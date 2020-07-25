#!/bin/bash

EXTDIS="HDMI-0"

TAGS="123456789"
LEFTSYM="<"
RIGHTSYM=">"
BARFG="#ffffff"
BARBG="#85000000"
BARFONT="Noto Sans:size=10"
BARH=18
BARX=0
# Make sure to adjust for BARH if you put the bar on the bottom! (i.e. y_orig = 1080-18)
BARY=0

INFF="/tmp/peachbar.fifo"
# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"

while read line; do
	MULTI=$(xrandr -q | grep "$EXTDIS" | awk -F" " '{ print $2 }')

	# if line is sara info
	if [[ "${line:0:1}" =~ ^[0-4].* ]]; then
		# monitor 0 (lemonbar says it's 1)
		MONLINE0="$(cut -d' ' -f1 <<<"$line")"
		TAGSTR0="$(peachbar-parsesara.sh $MONLINE0 $TAGS $LEFTSYM $RIGHTSYM)"

		if [ "$MULTI" = "connected" ]; then
			# monitor 1 (lemonbar says it's 0)
			MONLINE1="$(cut -d' ' -f2 <<<"$line")"
			TAGSTR1="$(peachbar-parsesara.sh $MONLINE1 $TAGS $LEFTSYM $RIGHTSYM)"
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

# pull information from sara
exec sara > "$INFF"
