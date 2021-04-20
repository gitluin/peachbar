#!/bin/sh

# sara-interceptor.sh splits sara's output into N fifos, one for each monitor.
#	It then writes to $PEACHFIFO to signal that there is an update.
#	When the Sara module gets called, it reads from the associated fifo!


# TODO: replace FIFO with file?

SARAFIFO="$1"
PEACHFIFO="$2"


SplitMonline() {
	LOCAL_MONLINE="$1"
	NUMSCREEN="$2"

	SINGLE_MONLINE="$(echo "$LOCAL_MONLINE" | cut -d' ' -f$NUMSCREEN)"

	echo "$SINGLE_MONLINE"
}

# from gitlab.com/mellok1488/dotfiles/panel
# TODO: bad
#trap 'trap - TERM; kill 0' TERM QUIT EXIT

# TODO: trap for resetting MULTI
# TODO: lemonbar-equivalent monitor detection
#	lemonbar offloads to randr when detected, XINERAMA otherwise
#	xrandr --list-monitors?
MULTI="$(seq 1 $(( $(xrandr --listactivemonitors | wc -l) - 1)))"

for i in $MULTI; do
	IFIFO="/tmp/sara-Mon$(($i - 1)).fifo"
	test -e "$IFIFO" || mkfifo -m 666 "$IFIFO"
done

while test "TRUE"; do
	read -r line

	if ! test -z "$line"; then
		# Output monitor info to its own fifo
		for i in $MULTI; do
			# Index from 0, heathen!
			IFIFO="/tmp/sara-Mon$(($i - 1)).fifo"
			SplitMonline "$line" "$i" > $IFIFO
		done

		echo "Sara" > $PEACHFIFO
	fi
	sleep 0.01
done < $SARAFIFO
