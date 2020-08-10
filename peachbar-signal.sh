#!/bin/sh

# Alert peachbar to update
# SIGUSR1 is 10 on x86/ARM and "most others"
# See man 7 signal
kill -10 "$(pgrep 'peachbar-sys')"
