#!/bin/sh

# Alert peachbar to update
# -10 is SIGUSR1
kill -10 "$(pgrep 'peachbar.sh')"
