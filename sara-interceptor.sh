#!/bin/sh

# sara-interceptor.sh splits sara's output into N fifos, one for each monitor.


InitFifos() {
	# TODO: lemonbar-equivalent monitor detection
	#	lemonbar offloads to randr when detected, XINERAMA otherwise
	#	xrandr --list-monitors?
	MULTI="$(seq 1 $(( $(xrandr --listactivemonitors | wc -l) - 1)))"

	for i in $MULTI; do
		IFIFO="/tmp/sara-Mon$(($i - 1)).fifo"

		test -e "$IFIFO" && ! test -p "$IFIFO" && sudo rm "$IFIFO"
		test -p "$IFIFO" || sudo mkfifo -m 777 "$IFIFO"
	done
}


SplitMonline() {
	LOCAL_MONLINE="$1"
	NUMSCREEN="$2"

	SINGLE_MONLINE="$(echo "$LOCAL_MONLINE" | cut -d' ' -f$NUMSCREEN)"

	echo "$SINGLE_MONLINE"
}

InitFifos


# TODO: trap for resetting MULTI
# from gitlab.com/mellok1488/dotfiles/panel
# TODO: bad
#trap 'trap - TERM; kill 0' TERM QUIT EXIT

while read -r line; do
	if ! test -z "$line"; then
		# Output monitor info to its own file
		for i in $MULTI; do
			# Index from 0, heathen!
			IFIFO="/tmp/sara-Mon$(($i - 1)).fifo"
			SplitMonline "$line" "$i" > $IFIFO
		done
	fi
done
