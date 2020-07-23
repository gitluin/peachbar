#!/bin/sh

# Action		muted			+/- as $1, $2 is the percent amount
test "$1" = "mute" && amixer set Master mute || amixer set Master "$2"%"$1" unmute

# Alert peachbar to update
# -10 is SIGUSR1
kill -10 "$(pgrep 'peachbar.sh')"
