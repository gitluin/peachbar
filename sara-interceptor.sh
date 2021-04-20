#!/bin/sh

# sara-interceptor.sh splits sara's output into N fifos, one for each monitor.
#	It then writes to $PEACHFIFO to signal that there is an update.
#	When the Sara module gets called, it reads from the associated fifo!


SARAFIFO="$1"
PEACHFIFO="$2"


# TODO: cleanup old files


InitFiles() {
	# TODO: lemonbar-equivalent monitor detection
	#	lemonbar offloads to randr when detected, XINERAMA otherwise
	#	xrandr --list-monitors?
	MULTI="$(seq 1 $(( $(xrandr --listactivemonitors | wc -l) - 1)))"

	for i in $MULTI; do
		IFILE="/tmp/sara-Mon$(($i - 1)).monline"
		if test -e "$IFILE"; then
			touch "$IFILE"
			chmod 666 "$IFILE"
		fi
	done
}


SplitMonline() {
	LOCAL_MONLINE="$1"
	NUMSCREEN="$2"

	SINGLE_MONLINE="$(echo "$LOCAL_MONLINE" | cut -d' ' -f$NUMSCREEN)"

	echo "$SINGLE_MONLINE"
}


# TODO: trap for resetting MULTI
# from gitlab.com/mellok1488/dotfiles/panel
# TODO: bad
#trap 'trap - TERM; kill 0' TERM QUIT EXIT

while test "TRUE"; do
	read -r line

	if ! test -z "$line"; then
		# Output monitor info to its own file
		for i in $MULTI; do
			# Index from 0, heathen!
			IFILE="/tmp/sara-Mon$(($i - 1)).monline"
			SplitMonline "$line" "$i" > $IFILE
		done

		echo "Sara" > $PEACHFIFO
	fi
	sleep 0.01
done < $SARAFIFO
