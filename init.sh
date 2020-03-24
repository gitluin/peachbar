#!/bin/sh

[[ $(pgrep -c "sbar_loop.sh") -ge 1 ]] && exit 1

INFF="/tmp/saralemon.fifo"
NAMEFILE=~/.sbar/.name

# Clear out any stale locks
9>&-
sudo rm -rf /tmp/sbarlock

# Clear out any stale fifos
[[ -e "$INFF" ]] && ! [[ -p "$INFF" ]] && sudo rm "$INFF"
[[ -p "$INFF" ]] || mkfifo -m 600 "$INFF"

echo "VOL: NA | o NA% | NA | NA NA% | $(date +'%m-%d-%y %R')" > "$NAMEFILE"

/ibin/sbar_audio.sh "" ""
/ibin/sbar_bright.sh "" ""
/ibin/sbar_battery.sh

exec /ibin/sbar_loop.sh
