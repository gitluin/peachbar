#!/bin/bash

Configure() {
	if test -f "$HOME/.config/peachbar/peachbar.conf"; then
		. "$HOME/.config/peachbar/peachbar.conf"

		# ------------------------------------------
		# wal integration
		if test "$USEWAL" = "TRUE" && test -f "$HOME/.cache/wal/colors.sh"; then
			. "$HOME/.cache/wal/colors.sh"

			BARFG="$foreground"
			BARBG="$background"
			INFOBG="$color1"
			OCCCOLBG="$color2"
			SELCOLBG="$color15"
		fi
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
}

Configure


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
trap "Configure" SIGUSR2
# Sleep until 10s up or signal received
# Useful for updating audio/brightness immediately
trap 'DUMMY=false' SIGUSR1
# from gitlab.com/mellok1488/dotfiles/panel
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT
while true; do
	STATUSLINE="%{B$MODULESBG}"

	# TODO: the DUMMY thicc trap wakes the whole statusline up, not just the
	#	module. Do I care?
	for MODULE in $MODULES; do
		STATUSLINE="$STATUSLINE$($MODULE)"
	done

	STATUSLINE="$STATUSLINE%{B-}"

	# Write STATUSLINE to FIFO
	echo "$STATUSLINE" > "$INFF"

	sleep 10 &
	wait $!
done
