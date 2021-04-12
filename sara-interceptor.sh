#!/bin/sh

SARAFIFO="$1"
PEACHFIFO="$2"


SplitMonline() {
	LOCAL_MONLINE="$1"
	NUMSCREEN="$2"

	SINGLE_MONLINE="$(echo "$LOCAL_MONLINE" | cut -d' ' -f$NUMSCREEN)"

	echo "$SINGLE_MONLINE"
}

# from gitlab.com/mellok1488/dotfiles/panel
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

while read line; do
	# TODO: lemonbar-equivalent monitor detection
	#	lemonbar offloads to randr when detected, XINERAMA otherwise
	#	xrandr --list-monitors?
	MULTI="$(( $(xrandr --listactivemonitors | wc -l) - 1))"

	# Output monitor info to its own fifo
	for (( i=0; i<$MULTI; i++ )); do
		IFIFO="sara-Mon$i.fifo"
		SplitMonline "$line" "$(($i + 1))" > $IFIFO
	done

	echo "ParseSara" > $PEACHFIFO
done < $SARAFIFO
