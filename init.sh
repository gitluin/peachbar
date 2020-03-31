#!/bin/sh

test "$(pgrep -c "sbar_loop.sh")" -ge 1 && exit 1

INFF="/tmp/saralemon.fifo"
NAMEFILE="/home/ishmael/.sbar/.name"

# Clear out any stale locks
9>&-
sudo rm -rf /tmp/sbarlock

# Clear out any stale fifos
test -e "$INFF" && ! test -p "$INFF" && sudo rm "$INFF"
test -p "$INFF" || sudo mkfifo -m 777 "$INFF"

echo "VOL: NA | o NA% | NA | NA NA% | $(date +'%m-%d-%y %R')" > "$NAMEFILE"

sbar_audio.sh "" ""
sbar_bright.sh "" ""
sbar_battery.sh

exec sbar_loop.sh
