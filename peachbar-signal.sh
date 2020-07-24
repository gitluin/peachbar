#!/bin/sh

# Alert peachbar to update
# sudo for when called by udev
# -10 is SIGUSR1
sudo kill -10 "$(pgrep 'peachbar.sh')"
