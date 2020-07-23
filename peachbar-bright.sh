#!/bin/sh

# Pass -A (up)/-U (down) as $1, amount as $2
light "$1" "$2"

# Alert peachbar to update
# -10 is SIGUSR1
kill -10 "$(pgrep 'peachbar.sh')"
