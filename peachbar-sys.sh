#!/bin/bash

if test -f "$HOME/.config/peachbar/peachbar.conf"; then
	. "$HOME/.config/peachbar/peachbar.conf"
else
	echo "Missing config file: $HOME/.config/peachbar/peachbar.conf"
	exit -1
fi

if test -f "$HOME/.config/peachbar/peachbar-modules.conf"; then
	. "$HOME/.config/peachbar/peachbar-modules.conf"
else
	echo "Missing modules.conf file: $HOME/.config/peachbar/peachbar-modules.conf"
	exit -1
fi


# ------------------------------------------
# Initialize
# ------------------------------------------
# Kill other peachbar.sh instances
# For some reason, pgrep and 'peachbar-*.sh'
#	don't play nice - something about the
#	[.].
PEACHPIDS="$(pgrep "peachbar-sys")"
for PEACHPID in $PEACHPIDS; do
	! test $PEACHPID = $$ && kill -9 $PEACHPID
done


# ------------------------------------------
# Main loop
# ------------------------------------------
# Reload config files on signal
trap ". $HOME/.config/peachbar/peachbar.conf && . $HOME/.config/peachbar/peachbar-modules.conf" SIGUSR2
# Sleep until 10s up or signal received
# Useful for updating audio/brightness immediately
trap 'DUMMY=false' SIGUSR1
# from gitlab.com/mellok1488/dotfiles/panel
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT
while true; do
	STATUSLINE="%{B$MODULESBG}"

	for MODULE in $MODULES; do
		STATUSLINE="$STATUSLINE$($MODULE)"
	done

	STATUSLINE="$STATUSLINE%{B-}"

	# Write STATUSLINE to FIFO
	#echo "PEACH{$STATUSLINE}" > "$INFF"
	echo "$STATUSLINE" > "$INFF"

	sleep 10 &
	wait $!
done
